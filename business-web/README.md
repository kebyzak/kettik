# kettik business

The venues' cabinet: venues, fields, tariffs and the day calendar with manual bookings. React + TypeScript on Vite, Russian only for now.

```sh
npm install
npm run dev     # http://localhost:5173/business/, proxies /auth and /biz to the API on :8080
npm run build   # dist/, served by Caddy under /business/
```

A business and its owner are added by hand (backend/README.md, Business); the owner signs in with the email code.
