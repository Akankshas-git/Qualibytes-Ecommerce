CODEBASE Full Report

This report contains per-file concise summaries and observations for the repository `qualibytes-ecommerce-app`.

---

# Summary of files already inspected

## `package.json`
- Purpose: Project manifest for the Next.js frontend.
- Key points: scripts `dev`, `build`, `start`, `migrate`; dependencies include `next@14.1.0`, `react`, `redux-toolkit`, `mongoose`, `jose`, `bcryptjs`, `sharp`, and testing/tools in `devDependencies`.
- Observations: `next-auth` is listed but not obviously used; `migrate` script uses `ts-node` to run `scripts/migrate-data.ts`.

## `next.config.js`
- Purpose: Next.js build config.
- Key points: `output: 'standalone'` for self-contained production build and `swcMinify: true`.

## `src/app/layout.tsx`
- Purpose: Global app layout for Next.js App Router.
- Key points: Includes `StoreProvider` (Redux), `ThemeProvider`, `AuthProvider`, `Navbar`, `Footer`, `AddedCart`, `MobileBottomMenu`, `ScrollToTopBtn`, and app-wide `Toaster`.
- Observations: Uses Google `Roboto` font; sets metadata for title/description.

## `src/lib/db.ts`
- Purpose: MongoDB (Mongoose) connection helper.
- Key points: Uses global caching (`global.mongoose`) to avoid multiple connections in serverless/hot-reload scenarios. Reads `MONGODB_URI` from env with fallback `mongodb://localhost:27017/easyshop`.
- Observations: Throws if `MONGODB_URI` is not defined (though fallback exists); connection options include `bufferCommands: false`.

## `src/lib/fetchDataFromApi.ts`
- Purpose: Browser-focused axios wrapper used by client code.
- Key points: Sets `baseURL` from `window.location.origin` or `NEXT_PUBLIC_API_URL`; creates `axiosInstance` with `withCredentials: true`; interceptors and helper methods read `document.cookie` and attach `Authorization: Bearer <token>`.
- Observations / Issue: Accesses `document`/`window` and `document.cookie` — not safe when imported in server components or during SSR. Recommend guarding or splitting client/server HTTP utilities.

## `src/middleware.ts`
- Purpose: Next.js middleware for route protection.
- Key points: Reads token from request via `getTokenFromRequest`, checks auth, redirects unauthenticated users for protected routes (`/checkout`, `/profile`, `/admin`), redirects authenticated users away from auth pages, injects `x-user-id` and `x-user-role` headers when authenticated.
- Observations: Good central route protection; uses `matcher` to limit middleware scope.

## `src/lib/auth/utils.ts`
- Purpose: JWT helper functions (generate/verify/get token/isAuthenticated/requireAuth/requireRole).
- Key points: Uses `jose` (`SignJWT`, `jwtVerify`), `JWT_SECRET` from env (fallback insecure string). Tokens set to expire in 30 days. `getTokenFromRequest` supports Authorization header `Bearer` and cookie `token`.
- Observations: Logs token verification details — avoid sensitive logs in production. Ensure strong `JWT_SECRET` in env.

## `src/app/api/auth/login/route.ts`
- Purpose: API route handler for login.
- Key points: Connects to DB, finds user (includes password using `.select('+password')`), checks password via model method, generates token payload `{ userId, role }`, sets HTTP-only cookie `token` and returns user + token in JSON.
- Observations: Cookie flags differ in routes; `maxAge` is set and `secure` toggled by `NODE_ENV`.

## `src/app/api/auth/register/route.ts`
- Purpose: API route handler for user registration.
- Key points: Validates input, checks existing user, creates user, generates token, sets HTTP-only cookie and returns user + token.

## `src/lib/models/user.ts`
- Purpose: Mongoose `User` model and schema.
- Key points: Fields: `name`, `email`, `password` (select: false), `role`, `avatar`, `addresses`. Pre-save hook hashes password using `bcryptjs`. Method `matchPassword` compares provided password with hashed password.

## `src/components/Navbar.tsx`
- Purpose: Site navbar component.
- Key points: Client component (`"use client"`), fetches auth status via `authenticated` action, shows profile menu when authenticated, contains search, links, theme toggle, link to source code, and Join/Login button.

---

# Next steps

I will continue reading the remaining text files in the repository and append per-file concise summaries to this report. I'll process files in batches and provide progress updates after every 4-6 files read.

(Progress: report created and key inspected files summarized.)


## Next batch: models, store, slices, utils, hooks, layoutSettings

### `src/lib/models/product.ts`
- Purpose: Mongoose `Product` schema/model.
- Key points: Fields include `originalId`, `title`, `description`, `price`, `oldPrice`, `categories`, `image` array, `rating`, `sales`, `amount`, `shop_category`, `unit_of_measure`, `colors`, and `sizes`. Timestamps enabled.
- Observations: `originalId` required/unique — implies migration from another dataset; images stored as string paths.

### `src/lib/models/order.ts`
- Purpose: Mongoose `Order` schema with TypeScript interfaces.
- Key points: `user` ref, `items` array (product ref, quantity, price), `total`, `shippingAddress`, `paymentMethod`, `status`, `paymentStatus`. Enums enforce allowed statuses. Model re-creation logic deletes existing `mongoose.models.Order` then defines the model.
- Observations: Exports typed interfaces `IOrder` and `IOrderItem` — helpful for server correctness.

### `src/lib/models/cart.ts`
- Purpose: Mongoose `Cart` schema and `ICart` interface.
- Key points: `user` unique, `items` (product ref, quantity, price), `total` auto-calculated in `pre('save')` hook. File deletes existing `Cart` model and also drops `carts` collection with `mongoose.connection.collections['carts']?.drop()`.
- Observations: Dropping the collection on import may be destructive in some environments; likely intended for dev/migration but risky in production.

### `src/lib/store.ts`
- Purpose: Factory to create Redux store (`makeStore`) using RTK.
- Key points: Reducers wired: `authSlice`, `cartSlice`, `sidebarSlice`. Exports typed `AppStore`, `RootState`, `AppDispatch`.

### `src/lib/features/cart/cartSlice.ts`
- Purpose: Client-side cart state management.
- Key points: Manages `cartItems`, `wishlists`, `isCartOpen`, `countValue`, `selectedSize`, `selectedColor`. Reads/writes to `localStorage`. Provides reducers for add/remove/increment/decrement, wishlist toggle, color/size selection, and cart UI toggle.
- Observations: Accesses `window`/`localStorage` directly inside initial state — safe because slice is used in client code; server imports should avoid this file.

### `src/lib/features/auth/authSlice.ts`
- Purpose: Client-side auth state.
- Key points: `isAuthenticated`, `currentUser` persisted to `localStorage`. Reducers for setting/removing user and auth flag.

### `src/lib/features/sidebar/sidebarSlice.ts`
- Purpose: UI slice for sidebar state.
- Key points: Toggles filter and profile nav open state.

### `src/lib/utils.ts`
- Purpose: Utility helpers.
- Key points: `cn` wrapper for classnames + tailwind merge, regex helper `rgx`, `totalPrice` for cart total, and `discountPercent`.

### `src/lib/hooks.ts`
- Purpose: Typed Redux hooks (`useAppDispatch`, `useAppSelector`, `useAppStore`).

### `src/lib/layoutSettings.ts`
- Purpose: Shop-specific layout configuration: hero images, filter options, and product card variants per shop (e.g., `bags`, `bakery`, `books`, `clothing`, `gadgets`, `grocery`, `makeup`, `medicine`).
- Observations: Centralized UI settings per shop make it easy to vary layout/filters per shop page.

## Next batch: API routes and homepage

### `src/app/api/products/route.ts`
- Purpose: Route handler for listing and creating products.
- Key points: Supports search, filtering (shop_category, categories, price range), pagination, sorting. `GET` returns products and pagination metadata. `POST` requires admin and creates product.
- Observations: Flexible query support; uses `originalId`/`shop_category` fields from model.

### `src/app/api/products/[productId]/route.ts`
- Purpose: CRUD operations for a single product identified by `originalId` (used as `productId`).
- Key points: `GET` finds by `originalId`; `POST` creates; `PUT` updates (admin only); `DELETE` deletes (admin only).

### `src/app/api/products/featured/route.ts`
- Purpose: Returns featured products for a category.
- Key points: Maps frontend categories to DB categories, builds a score using `rating * (sales + 1)` and returns top 8 using aggregation.
- Observations: Contains debug `console.log` statements — consider reducing in production.

### `src/app/api/products/books/route.ts`
- Purpose: Returns recent `books` category products (limit 10).

### `src/app/api/singleProduct/[slug]/route.ts`
- Purpose: Fetch single product by `originalId` (slug) or fallback to `_id` when slug is an ObjectId.

### `src/app/api/cart/route.ts` and `src/app/api/cart/[productId]/route.ts`
- Purpose: Cart management (get user's cart, add/update items, clear cart, update item quantity, remove item).
- Key points: Uses `requireAuth` to ensure authenticated requests, populates product details in response, handles cart creation and updates, recalculates totals. Many debug `console.log` statements exist.
- Observations: Good behavior for populating product details; logs are verbose and may expose info in production.

### `src/app/api/orders/route.ts` and `src/app/api/orders/[orderId]/route.ts`
- Purpose: Orders listing, creation, single-order retrieval, status update (admin), and cancellation.
- Key points: `POST` creates order from provided items, maps shipping/billing addresses, clears cart, and persists order. `GET` for orders paginates and populates product details. Single-order `GET/PUT/DELETE` restricts actions appropriately (auth/admin checks).

### `src/app/actions.ts`
- Purpose: Server actions for cookie management using Next.js `cookies()` helper.
- Key points: `createCookies` sets `token` cookie (note: `httpOnly` set to `false` here), `removeCookies` deletes the cookie, `getCookies` reads cookie, and `authenticated` returns boolean presence of cookie.
- Observations: `createCookies` sets `httpOnly: false` and `secure: false` which may reduce cookie security; values appear tuned for EC2/dev. Consider environment-aware secure flags.

### `src/app/page.tsx`
- Purpose: Home page composition.
- Key points: Uses `HeroSlider`, `BannerSlider`, `ShopCategories`, `BooksCategory`, `BekaryCategories`, and `FeaturedProducts`. Passes `searchParams.featured` into `FeaturedProducts`.

## Next batch: UI components (search, cart, banners, featured, product display)

### `src/components/SearchBar.tsx`
- Purpose: Client search form used in the navbar and search areas.
- Key points: Supports an optional shop selector, reads `shops.json`, uses Next.js `useRouter` to navigate to `/shops/<shop>?q=<query>`. Uses `Select` component for shop selection and `Input` for query input.

### `src/components/AddedCart.tsx`
- Purpose: Floating cart sidebar and compact cart indicator.
- Key points: Uses Redux `cartSlice` state, Framer Motion animations, populates item images and totals, supports checkout redirect and login redirection for unauthenticated users. Persists cart interactions and shows item-level remove and total price.
- Observations: Handles client-only rendering (guarded with `useEffect` isClient). Uses `totalPrice` util.

### `src/components/BannerSlider.tsx`
- Purpose: Visual banner carousel for homepage.
- Key points: Uses custom `Carousel` components and `embla-carousel-autoplay` plugin; maps images and renders responsive carousel.

### `src/components/FeaturedProducts.tsx`
- Purpose: Client component to fetch and display featured product cards.
- Key points: Fetches `/api/products/featured?category=<>` on mount, shows skeletons while loading, renders a grid of `ProductCard` components and a `FeaturedNav`.

### `src/components/cards/ProductCard.tsx`
- Purpose: Central product card wrapper that chooses a card variant.
- Key points: Switches between `CardOne`, `CardTwo`, `CardThree`, `CardFour`, and `BookCard` based on `variants` prop.

### `src/components/SingleProduct.tsx`
- Purpose: Product detail composition used on product pages.
- Key points: Composes `ProductImageSlider`, `SelectVariants`, `Counter`, `AddToCartBtnWrapper`, and wishlist; shows price, old price, availability, categories, and shop links.

### `src/components/sliders/ProductImageSlider.tsx`
- Purpose: Embla-based image carousel with thumbnail strip for product images.
- Key points: Synchronizes main carousel with thumbnail carousel and supports single-image fallback.

### `src/components/loader/Skeleton.tsx`
- Purpose: Small skeleton placeholder used during loading lists/grids.

## Next batch: Interaction components, theme, footer, mobile UI

### `src/components/providers/AuthProvider.tsx`
- Purpose: Client-side provider that checks auth status on mount and updates Redux auth state.
- Key points: Calls `/api/auth/check` and then uses `fetchData.get('/auth/me')` to populate `currentUser` and `isAuthenticated` in Redux.
- Observations: Depends on `fetchData` (which reads cookies via `document.cookie`), so ensure client-only usage.

### `src/components/AddToCartWrapper.tsx`
- Purpose: Add-to-cart button wrapper that supports multiple button styles and counter behavior.
- Key points: Integrates with Redux cart slice, handles clothing-specific validations (requires color & size), and supports multiple UI variants.

### `src/components/AddToWishlist.tsx`
- Purpose: Toggle wishlist UI with animation.
- Key points: Uses Redux `toggleToWishlists` to add/remove, shows filled vs outline heart icons via Framer Motion.

### `src/components/Counter.tsx`
- Purpose: Small counter component wired to cart slice to increment/decrement item amount.

### `src/components/ToggleTheme.tsx` and `src/components/ThemeProvider.tsx`
- Purpose: Theme toggle and wrapper using `next-themes`.
- Key points: `ToggleTheme` exposes a dropdown to select `light`, `dark`, or `system` themes; `ThemeProvider` is a thin wrapper over `NextThemesProvider`.

### `src/components/Footer.tsx`
- Purpose: Global site footer with newsletter subscription, links, social buttons, credits, and copyright.
- Key points: Includes external links and author credit; uses `Button` and `Input` UI primitives.

### `src/components/MobileBottomMenu.tsx`, `src/components/MobileMenu.tsx`, and `src/components/Modal.tsx`
- Purpose: Mobile navigation and modal UI components.
- Key points: `MobileBottomMenu` shows bottom navigation and toggles `MobileMenu`/search/cart; `MobileMenu` includes links and theme toggle; `Modal` is an animated generic modal wrapper.

## Next batch: Forms (login, signup, contact, shipping/billing, profile)

### `src/components/forms/LoginForm.tsx`
- Purpose: Login form UI using `react-hook-form` + `zod` validation and the project's `Form` primitives.
- Key points: On submit calls `fetchData.post('/auth/login')`, sets cookie with `createCookies`, updates Redux auth state, and handles redirect logic including a special case for `/checkout` when cart is empty.

### `src/components/forms/SignupForm.tsx`
- Purpose: Signup form with `zod` validation.
- Key points: Submits to `/auth/register`, sets cookie using `createCookies`, updates auth state, and handles toast notifications; logs details for debugging.

### `src/components/forms/ContactForm.tsx`
- Purpose: Simple contact form using `react-hook-form` and `zod` for validation; currently logs submission to console.

### `src/components/forms/ShippingAddressForm.tsx` and `src/components/forms/BillingAddressForm.tsx`
- Purpose: Address forms for checkout flows with validation and callbacks for parent component to collect data. Both provide `onFormDataChange` to surface values.

### `src/components/forms/ProfileForm.tsx`
- Purpose: Profile edit form that pre-fills `currentUser` from Redux and supports image upload preview, name, email, and bio fields.

## Next batch: UI primitive components (`ui/*`)

### `src/components/ui/button.tsx`
- Purpose: Reusable `Button` component built with `class-variance-authority` providing `variant` and `size` props and optional `asChild` to render other elements.

### `src/components/ui/input.tsx`, `src/components/ui/textarea.tsx`, `src/components/ui/select.tsx`
- Purpose: Basic form primitives (`Input`, `Textarea`, and Radix-based `Select`) with consistent Tailwind classes and `cn` utility.

### `src/components/ui/toaster.tsx` and `src/components/ui/use-toast.ts`
- Purpose: Lightweight toast system inspired by `react-hot-toast`. `use-toast` provides an imperative `toast()` helper and state; `Toaster` renders toasts using `Toast` primitives.

### `src/components/ui/card.tsx`, `src/components/ui/label.tsx`, and `src/components/ui/accordion.tsx`
- Purpose: Small presentational primitives (Card, Label, Accordion) wrapping Radix primitives and providing consistent styles.

Note: The `ui` primitives are designed to be small, composable, and consistent across the app. They rely on Radix UI and utility functions like `cn`.

### Remaining `ui` primitives

- `src/components/ui/dropdown-menu.tsx`: Radix-based dropdown primitives and helpers (items, groups, submenus, radio/checkbox items) with consistent styling.
- `src/components/ui/table.tsx`: Simple responsive table wrappers (`Table`, `TableHeader`, `TableBody`, `TableRow`, `TableCell`, etc.).
- `src/components/ui/toast.tsx`: Radix `Toast` primitives (Provider, Viewport, Root, Title, Description, Close, Action) with variants (success, destructive).
- `src/components/ui/carousel.tsx`: Embla-based carousel wrapper exposing `Carousel`, `CarouselContent`, `CarouselItem`, and navigation controls.
- `src/components/ui/popover.tsx`: Radix `Popover` primitives for lightweight popover UI.






