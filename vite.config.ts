import { defineConfig, loadEnv } from 'vite';
import RubyPlugin from 'vite-plugin-ruby';
import vue from '@vitejs/plugin-vue';
import dns from 'dns';

function mutateCookieAttributes (proxy) {
  proxy.on('proxyRes', function (proxyRes, req, res) {
    if (proxyRes.headers['set-cookie']) {
      proxyRes.headers['set-cookie'] = (proxyRes.headers['set-cookie']).map(h => {
        return h.replace(/Domain=.*;/, 'Domain=localhost; Secure;')
      })
    }
  })
}

function setHostHeader (proxy) {
  const host = new URL(process.env.VITE_PORTAL_API_URL).hostname;

  proxy.on('proxyReq', function (proxyRes) {
    proxyRes.setHeader('host', host)
  })
}

export default ({ command, mode }) => {
  process.env = { ...process.env, ...loadEnv(mode, process.cwd()) }

  // Defaults locale to en
  process.env.VITE_LOCALE = process.env.VITE_LOCALE || 'en'

  let portalApiUrl = process.env.VITE_PORTAL_API_URL;
  if (!portalApiUrl.endsWith('/')) {
    portalApiUrl += '/'
  }

  const subdomainR = new RegExp(/http:\/\/(.*)localhost/)
  if (subdomainR.test(portalApiUrl)) {
    portalApiUrl = 'http://localhost' + portalApiUrl.replace(subdomainR, '')
  }

  // required to prevent localhost from being rendered as 127.0.0.1
  dns.setDefaultResultOrder('verbatim')

  return defineConfig({
    define: {
      'process.env.development': JSON.stringify('development'),
      'process.env.production': JSON.stringify('production'),
    },
    plugins: [
      RubyPlugin(),
      vue()
    ],
    build: {
      rollupOptions: {
        external: ['shiki/onig.wasm']
      }
    },
    server: {
      proxy: {
        '^/api': {
          changeOrigin: true,
          target: portalApiUrl,
          configure: (proxy, options) => {
            mutateCookieAttributes(proxy)
            setHostHeader(proxy)
          }
        }
      }
    }
  })
}
