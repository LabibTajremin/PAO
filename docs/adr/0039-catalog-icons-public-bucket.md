# ADR-0039: Catalog icons live in the public bucket

- Status: Accepted
- Date: 2026-11-21
- Source: the owner's 2026-11 update note (items iv, vi, vii) and P22.

## Context

Admins give each category and service an icon: one of the library icons the apps ship
(`iconKey`), or their own, uploaded or added from a link. Every customer and partner app
loads these icons, signed in or not, often from one mobile-carrier IP. They are public,
rarely change and must never be hotlinked from someone else's site.

## Decision

1. **Storage.** Uploaded and linked icons are stored in `S3_BUCKET_PUBLIC`, under
   `catalog-icons/<id>.<svg|png|webp>`. The API makes that prefix, and only that prefix,
   readable without signing (an S3 bucket policy set at start-up). The private bucket and
   every other object stay private.
2. **Address.** `iconUrl` is `<public base>/catalog-icons/<id>.<ext>`, where the public base
   is `Storage:PublicBaseUrl` (`S3_PUBLIC_BASE_URL`, e.g. a CDN in front of the bucket) or,
   when empty, `<S3_PUBLIC_ENDPOINT>/<S3_BUCKET_PUBLIC>`. A category or service accepts only
   an `iconUrl` that starts with that base, so it always points at a file we hold.
3. **Upload.** `POST /v1/admin/catalog/icons` takes the file in the JSON body (base64). SVG up
   to 100 KB is parsed without DTDs and sanitised: only drawing elements and attributes are
   kept; scripts, event handlers, `foreignObject`, external references and CSS `url()` are
   removed. PNG or WebP up to 200 KB must be square, at least 96 × 96 and carry
   transparency. The stored file is the sanitised one; its id is new, so the URL can be cached
   forever.
4. **From a link.** `POST /v1/admin/catalog/icons/from-link` downloads the URL once: HTTPS
   only, a public address only (loopback, private, link-local and similar ranges are refused
   after DNS resolution, at connect time), 5 seconds, at most 200 KB, no redirects. The file
   then goes through the same checks as an upload.
5. **Library.** `GET /v1/admin/catalog/icons` lists the library keys, so the admin picker and
   the apps agree on the set.
6. Every stored icon writes an audit entry (`catalog.icon_added`, with the source).
   Changing a category or service icon is audited like any catalog change.

## Why

Serving icons through the API would put every icon load behind the per-IP rate limit (60 a
minute), which a catalog screen on a shared carrier IP would exceed. A JSON body keeps the
upload inside the existing edge (spec validation, 1 MB body limit, audit) instead of adding
multipart handling. Sanitising instead of only rejecting lets admins use SVGs exported from
common editors, which carry metadata and editor attributes.

## Consequences

- Storage that has no bucket policies (Cloudflare R2) needs public access turned on for the
  bucket, or a custom domain, set as `S3_PUBLIC_BASE_URL`. `docs/guides/deployment.md` says how.
- The apps show uploaded icons as a single-colour mask in the accent colour, so a coloured
  PNG renders as its silhouette; the admin preview shows this before saving.
