import os

from flask import Flask, render_template, request
from redis import Redis
import socket

VERSION = os.environ.get("VERSION", "DEFAULT_VERSION")


class MyRedis:
    def __init__(self) -> None:
        self.host = os.environ.get("REDIS_HOST")

        if self.host:
            self.r = Redis(host=self.host)

    def get_users(self):
        if self.host:
            users = self.r.smembers("users")
            print("users :: ", users)
            return users
        return ["NO DB YET"]

    def set_user(self, user):
        if self.host:
            self.r.sadd("users", user)
            print("NO DB YET")


r = MyRedis()
app = Flask(__name__)


@app.route("/")
def index():
    try:
        host_name = socket.gethostname()
        host_ip = socket.gethostbyname(host_name)
        user_ip = (request.remote_addr,)
        r.set_user(user_ip[0])
        users = r.get_users()
        return render_template(
            "index.html",
            hostname=host_name,
            ip=host_ip,
            version=VERSION,
            user_ip=user_ip,
            users=users,
        )
    except Exception as ex:
        return render_template("error.html", error=str(ex))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
