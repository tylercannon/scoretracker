defmodule ScoreTrackerWeb.ContentSecurityPolicy do
  @moduledoc """
  Plug used to generate a content security policy
  and functions for generating an nonce value
  to use in the policy for in-line script and
  style elements.
  """
  @process_key :plug_nonce

  @doc """
  Put the content security response header on the connection
  """
  @spec put_content_security_policy(Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t()
  def put_content_security_policy(conn, _opts) do
    nonce = get_nonce()

    # We want to allow the live reload iframe when running locally
    child_src =
      if Application.get_env(:score_tracker, :dev_routes) do
        "self"
      else
        "none"
      end

    policy =
      Enum.join(
        [
          "base-uri 'self'",
          "child-src '#{child_src}'",
          "default-src 'self'",
          "frame-ancestors 'none'",
          "img-src 'self' data:",
          "media-src 'none'",
          "object-src 'none'",
          "script-src 'self' 'nonce-#{nonce}'",
          "style-src 'self' 'nonce-#{nonce}'",
          "worker-src 'none'"
        ],
        "; "
      )

    Plug.Conn.put_resp_header(conn, "content-security-policy", policy)
  end

  @doc """
  Get the nonce value.

  Generates a new value and stores it in the process
  dictionary if one does not exist.

  Based on `get_csrf_token` in the [plug module](https://github.com/elixir-plug/plug/blob/v1.18.1/lib/plug/csrf_protection.ex#L224-L232)
  """
  @spec get_nonce() :: String.t()
  def get_nonce do
    if nonce = Process.get(@process_key) do
      nonce
    else
      nonce =
        32
        |> :crypto.strong_rand_bytes()
        |> Base.url_encode64(padding: false)

      Process.put(@process_key, nonce)
      nonce
    end
  end
end
