# Magic Link Authentication System

This document describes the magic link authentication system implemented for the application.

## Overview

The authentication system uses Phoenix.Token for passwordless authentication via magic links sent by email. It replaces the previous Ash Authentication system with a simpler, standard Phoenix-based implementation.

## Architecture

### Core Components

#### 1. Magic Link Service (`lib/thexstack/accounts/magic_link.ex`)

The main service module that handles:
- `request_magic_link(scope, email)` - Generates a signed token and sends magic link email
- `verify_magic_link(scope, token)` - Verifies token and creates/authenticates user

Features:
- Email allowlist: Only `hello@nicolasdular.com` and `hello@philippspiess.com` can request magic links
- Tokens are valid for 1 hour
- Automatic user creation on first login
- Sets `confirmed_at` timestamp on authentication

#### 2. Authentication Plugs

**SetScope Plug** (`lib/thexstack_web/plugs/set_scope.ex`)
- Loads the current user from the session (clearing invalid sessions)
- Assigns `conn.assigns.current_user`
- Builds `%Thexstack.Scope{}` for each request and stores it as `conn.assigns.current_scope`
- Domains expect the scope as their first argument

**RequireAuth Plug** (`lib/thexstack_web/plugs/require_auth.ex`)
- Enforces authentication for protected routes
- Returns 401 JSON error if not authenticated
- Use this plug on controllers or specific actions that need protection
- Expects the scope plug (`SetScope`) to run first so that `conn.assigns.current_user` is available

#### 3. Controllers

**AuthController** (`lib/thexstack_web/controllers/auth_controller.ex`)
- `POST /api/auth/request-magic-link` - Request a magic link

**SessionController** (`lib/thexstack_web/controllers/session_controller.ex`)
- `GET /auth/:token` - Handle magic link callback and create session
- `DELETE /auth/sign_out` - Sign out (clears session)

**UserController** (`lib/thexstack_web/controllers/user_controller.ex`)
- `GET /api/user/me` - Get current user info (requires authentication)

#### 4. Email Sender

**SendMagicLinkEmail** (`lib/thexstack/accounts/user/senders/send_magic_link_email.ex`)
- Sends magic link emails using Swoosh
- Unchanged from original implementation

## Usage Examples

### Request a Magic Link (Frontend)

```javascript
const response = await fetch('/api/auth/request-magic-link', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    email: 'hello@nicolasdular.com'
  })
});

const result = await response.json();
// { success: true, message: "Magic link sent to your email" }
```

### Protect a Controller Action

```elixir
defmodule MyAppWeb.ProtectedController do
  use MyAppWeb, :controller

  alias ThexstackWeb.Plugs.RequireAuth

  # Require auth for all actions
  plug RequireAuth

  def index(conn, _params) do
    user = conn.assigns.current_user
    # user is guaranteed to exist here
    json(conn, %{user: user})
  end
end
```

### Protect Specific Actions

```elixir
defmodule MyAppWeb.MixedController do
  use MyAppWeb, :controller

  alias ThexstackWeb.Plugs.RequireAuth

  # Only protect specific actions
  plug RequireAuth when action in [:edit, :update, :delete]

  def index(conn, _params) do
    # Public action - no auth required
  end

  def edit(conn, _params) do
    # Protected action - auth required
    user = conn.assigns.current_user
  end
end
```

### Get Current User

```elixir
# In any controller or LiveView
user = conn.assigns.current_user

# Using helper
import ThexstackWeb.AuthHelpers

if authenticated?(conn) do
  user = get_current_user(conn)
end
```

## Session Management

- Sessions are stored in cookies (configured in endpoint)
- Session contains only `user_id`
- User is loaded on each request by the `Authenticate` plug
- Sign out clears the entire session

## Security Features

1. **Signed Tokens**: Uses Phoenix.Token with HMAC signature
2. **Time-Limited**: Tokens expire after 1 hour
3. **Email Allowlist**: Only specific emails can authenticate
4. **CSRF Protection**: Enabled for browser requests
5. **Secure Sessions**: Configured in endpoint with signing salt

## API Endpoints

### Public Endpoints

- `POST /api/auth/request-magic-link` - Request magic link
  - Body: `{"email": "user@example.com"}`
  - Returns: `{"success": true, "message": "Magic link sent to your email"}`
  - Error: `{"error": "Email not authorized"}` (403)

- `GET /auth/:token` - Magic link callback (browser only)
  - Sets session and redirects to home

- `DELETE /auth/sign_out` - Sign out
  - Clears session
  - Returns: `{"success": true}`

### Protected Endpoints (Require Authentication)

- `GET /api/user/me` - Get current user
  - Returns: `{"data": {"id": 1, "email": "...", "confirmed_at": "..."}}`
  - Error: 401 if not authenticated

## Testing

### Manual Testing

1. Request a magic link:
```bash
curl -X POST http://localhost:4000/api/auth/request-magic-link \
  -H "Content-Type: application/json" \
  -d '{"email": "hello@nicolasdular.com"}'
```

2. Check mailbox (in development: http://localhost:4000/dev/mailbox)

3. Click the magic link or copy the token

4. Access protected endpoint with session cookie

### Unit Testing

```elixir
# Test magic link request
setup do
  %{scope: Thexstack.Factory.scope_fixture(name: :api)}
end

test "request_magic_link/1 sends email for allowed address", %{scope: scope} do
  assert {:ok, :sent} = MagicLink.request_magic_link(scope, "hello@nicolasdular.com")
end

test "request_magic_link/1 rejects unauthorized email", %{scope: scope} do
  assert {:error, :not_allowed} = MagicLink.request_magic_link(scope, "unauthorized@example.com")
end

# Test token verification
test "verify_magic_link/1 creates user on first login", %{scope: scope} do
  token = Phoenix.Token.sign(ThexstackWeb.Endpoint, "magic_link", "hello@nicolasdular.com")

  assert {:ok, user} = MagicLink.verify_magic_link(scope, token)
  assert user.email == "hello@nicolasdular.com"
  assert user.confirmed_at
end
```

## Migration from Ash Authentication

The new system removes dependencies on:
- `AshAuthentication`
- `AshAuthentication.Phoenix.Router`
- `AshAuthentication.Plug.Helpers`

Key changes:
1. Session management uses standard Phoenix `put_session/3` instead of `store_in_session/2`
2. User loading uses standard Ecto queries instead of Ash
3. Authentication plugs are custom implementations
4. No more Ash changesets for authentication

## Configuration

### Email Domain

Set the `EMAIL_DOMAIN` environment variable:
```bash
export EMAIL_DOMAIN=yourdomain.com
```

### Token Salt

Ensure your endpoint has a secure signing salt configured:
```elixir
# config/config.exs
config :thexstack, ThexstackWeb.Endpoint,
  # ... other config
  secret_key_base: "..." # Should be secure in production
```

## Future Enhancements

Potential improvements:
1. Add rate limiting for magic link requests
2. Support for email verification (separate from authentication)
3. Remember me functionality with longer-lived tokens
4. Admin interface for managing allowed emails
5. Audit logging for authentication events
