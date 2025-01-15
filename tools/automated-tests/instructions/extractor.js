import puppeteer from "puppeteer";
import fs from "fs/promises";
import debug from "debug";
import path from "path";
import yaml from "js-yaml";
import fastGlob from "fast-glob";
import matter from "gray-matter";

const log = debug("tests:extractor");

async function copyFromClipboard(page) {
  const copiedText = await page.evaluate(async () => {
    const instruction = await navigator.clipboard.readText();
    return instruction;
  });

  return copiedText;
}

async function extractPrereqsBlocks(page) {
  // We extract instructions from codeblocks that have data-test-prereqs='block'.
  // As an alternative, the prereq (accordion-item) could have the data-test-prereqs set,
  // and we could extract all the codeblocks it contains.
  const instructions = [];
  const blocks = await page.$$("[data-test-prereqs='block']");

  for (const elem of blocks) {
    if (await elem.isVisible()) {
      const copy = await elem.$(".copy-action");
      await copy.evaluate((e) => e.click());

      const copiedText = await copyFromClipboard(page);
      instructions.push(copiedText);
    }
    await elem.dispose();
  }
  return instructions;
}

async function extractPrereqs(page) {
  const blocks = [];
  // Handle the accordion gracefully, we need to click on each item (visible ones only).
  const [_prereq, ...prerequisites] = await page.$$(
    '[data-test-id="prereqs"] > *'
  );

  let extractedBlocks = await extractPrereqsBlocks(page);
  blocks.push(...extractedBlocks);

  for (const prereq of prerequisites) {
    if (await prereq.isVisible) {
      const trigger = await prereq.$(".accordion-trigger");
      await trigger.evaluate((e) => e.click());
    }
    extractedBlocks = await extractPrereqsBlocks(page);
    blocks.push(...extractedBlocks);
    await prereq.dispose();
  }

  return { blocks };
}

async function extractSetup(page) {
  // Fetch all elements that have data-test-setup and copy its value.
  const instructions = [];
  const setups = await page.$$("[data-test-setup]");

  for (const elem of setups) {
    if (await elem.isVisible()) {
      const instruction = await elem.evaluate((el) => el.dataset.testSetup);
      let key;
      try {
        const json = JSON.parse(instruction);
        instructions.push(json);
      } catch (error) {
        // Not a json, for products/platforms that don't have versions.
        instructions.push(instruction);
      }
    }
    await elem.dispose();
  }

  return instructions;
}

async function extractSteps(page) {
  const instructions = [];
  const steps = await page.$$("[data-test-step]");

  for (const elem of steps) {
    if (await elem.isVisible()) {
      const step = await elem.evaluate((el) => el.dataset.testStep);

      if (step === "block") {
        // copy code block
        const copy = await elem.$(".copy-action");
        await copy.evaluate((e) => e.click());

        const copiedText = await copyFromClipboard(page);
        instructions.push(copiedText);
      } else {
        // validation-type step
        const parsedInstruction = JSON.parse(step);

        instructions.push(parsedInstruction);
      }
    }
    await elem.dispose();
  }
  return instructions;
}

async function writeInstructionsToFile(url, config, platform, instructions) {
  let runtime = platform;
  if (runtime === "on-prem") {
    runtime = "gateway";
  }
  const instructionsFile = path.join(
    config.outputDir,
    url.pathname,
    `${runtime}.yaml`
  );
  const outputDir = path.dirname(instructionsFile);
  await fs.mkdir(outputDir, { recursive: true });

  await fs.writeFile(instructionsFile, yaml.dump(instructions), "utf-8");

  return instructionsFile;
}

export async function extractInstructionsFromURL(uri, config, browser) {
  const url = new URL(uri);

  const page = await browser.newPage();

  try {
    log(`Extracting instructions from: ${url}`);
    await page.goto(url, { waitUntil: "domcontentloaded" });

    const platforms = await page.evaluate(() => {
      const dropdown = document.querySelector(
        "select#deployment-topology-switch"
      );
      if (!dropdown) return [];

      return Array.from(dropdown.options).map((option) => option.value);
    });

    for (const platform of platforms) {
      await page.select("select#deployment-topology-switch", platform);

      const setup = await extractSetup(page);
      const prereqs = await extractPrereqs(page);
      const steps = await extractSteps(page);
      const instructionsFile = await writeInstructionsToFile(
        url,
        config,
        platform,
        {
          setup,
          prereqs,
          steps,
        }
      );

      log(`  Instructions extracted successfully to ${instructionsFile}`);
    }
  } catch (error) {
    log("There was an error extracting the instructions:", error);
  } finally {
    await page.close();
  }
}

async function testeableUrlsFromFiles(config) {
  const howTosUrls = [];
  const howToFiles = await fastGlob("../../app/_how-tos/**/*");

  for (const file of howToFiles) {
    const { data: frontmatter, content } = matter.read(file);

    const isTesteable =
      frontmatter.products &&
      frontmatter.products.length === 1 &&
      frontmatter.products.includes("gateway");

    if (isTesteable) {
      const skipHowTo =
        content.includes("@todo") || frontmatter.automated_tests === false;
      if (skipHowTo) {
        const relativeFilePath = file.replace("../../", "");
        if (frontmatter.automated_tests === false) {
          log(
            `Skipping file: ${relativeFilePath}, it's tagged with automated_tests=false`
          );
        } else {
          log(`Skipping file: ${relativeFilePath}, it's tagged with @todo.`);
        }
      } else {
        const fileToUrl = file
          .replace("../../app/_how-tos/", "")
          .replace(".md", "/");
        howTosUrls.push(`${config.baseUrl}/how-to/${fileToUrl}`);
      }
    }
  }
  return howTosUrls;
}

export async function generateInstructionFiles(config) {
  const testeableUrls = await testeableUrlsFromFiles(config);
  const browser = await puppeteer.launch();
  try {
    await browser
      .defaultBrowserContext()
      .overridePermissions(new URL(config.baseUrl).origin, ["clipboard-read"]);

    for (const uri of testeableUrls) {
      await extractInstructionsFromURL(uri, config, browser);
    }
  } catch (error) {
    throw error;
  } finally {
    browser.close();
  }
}
