import json
import threading
import time
import unittest
from urllib.request import Request, urlopen
from urllib.error import HTTPError
from server import AuthServer


class APITests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = AuthServer(("127.0.0.1", 0))
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.base = f"http://127.0.0.1:{cls.server.server_port}"

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=2)

    def request(self, path, body=None, token=None):
        headers = {"Content-Type": "application/json"}
        if token:
            headers["Authorization"] = f"Bearer {token}"
        req = Request(self.base + path, data=None if body is None else json.dumps(body).encode(), headers=headers)
        try:
            response = urlopen(req, timeout=2)
        except HTTPError as error:
            response = error
        with response:
            return response.status, json.load(response)

    def login(self):
        status, body = self.request("/auth/login", {"email": "demo@example.com", "password": "123456"})
        self.assertEqual(status, 200)
        return body

    def test_login_and_profile(self):
        body = self.login()
        self.assertEqual(set(body), {"accessToken", "user"})
        self.assertTrue(body["accessToken"])
        status, user = self.request("/auth/me", token=body["accessToken"])
        self.assertEqual(status, 200)
        self.assertEqual(user, body["user"])
        self.assertEqual(set(user), {"id", "fullName", "email"})

    def test_wrong_password(self):
        status, body = self.request("/auth/login", {"email": "demo@example.com", "password": "wrong"})
        self.assertEqual(status, 401)
        self.assertNotIn("accessToken", body)

    def test_missing_token(self):
        self.assertEqual(self.request("/auth/me")[0], 401)

    def test_invalid_token(self):
        self.assertEqual(self.request("/auth/me", token="invalid")[0], 401)

    def test_expired_token(self):
        token = self.login()["accessToken"]
        with self.server.session_lock:
            self.server.sessions[token] = time.time() - 1
        self.assertEqual(self.request("/auth/me", token=token)[0], 401)

    def test_malformed_fields(self):
        self.assertEqual(self.request("/auth/login", {"email": 123, "password": []})[0], 400)
        self.assertEqual(self.request("/auth/login", ["not", "an object"])[0], 400)

    def test_sessions_are_independent(self):
        first = self.login()["accessToken"]
        second = self.login()["accessToken"]
        self.assertNotEqual(first, second)
        with self.server.session_lock:
            self.server.sessions.pop(first)
        self.assertEqual(self.request("/auth/me", token=first)[0], 401)
        self.assertEqual(self.request("/auth/me", token=second)[0], 200)


if __name__ == "__main__":
    unittest.main(verbosity=2)
