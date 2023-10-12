# Stub: GitHub API

## Usage

1. Start the stub

    ```bash
    ./set-up.sh
    ```

2. Call the API

    ```bash
    curl -X GET \
        -H "Authorization: Bearer jwt" \
        -H "Accept: application/vnd.github.v3+json" \
        http://localhost:8080/app/installations

    curl -X POST \
        -H "Authorization: Bearer jwt" \
        -H "Accept: application/vnd.github.v3+json" \
        http://localhost:8080/app/installations/46679910/access_tokens
    ```

3. Stop the stub

    ```bash
    ./tear-down.sh
    ```
