import httpx

BASE_URL = "https://cluster.fuck"
ENDPOINT = "/api2/json/access/ticket"


class ProxmoxManager(httpx.AsyncClient):
    def __init__(self) -> None:
        pass

    def get_token(self):
        pass


if __name__ == "__main__":
    manager = ProxmoxManager()
