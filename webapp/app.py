import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

from flask import Flask, Response, render_template, request, stream_with_context

BASE_DIR = Path(__file__).resolve().parent.parent
SCRIPT_PATH = BASE_DIR / "elastic-init.sh"

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 500 * 1024 * 1024  # 500 MB upload safety cap

ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")

DEFAULTS = {
    "es_host": os.environ.get("ELASTIC_INIT_ES_HOST", "http://127.0.0.1"),
    "es_port": os.environ.get("ELASTIC_INIT_ES_PORT", "9200"),
    "onto_repo": os.environ.get(
        "ELASTIC_INIT_ONTO_REPO",
        "https://github.com/medizininformatik-initiative/fhir-ontology-generator/releases/download",
    ),
    "onto_git_tag": os.environ.get("ELASTIC_INIT_ONTO_GIT_TAG", ""),
    "download_filename": os.environ.get("ELASTIC_INIT_DOWNLOAD_FILENAME", "elastic.zip"),
    "force_reinstall": os.environ.get("ELASTIC_INIT_FORCE_REINSTALL", "false"),
}


def check_auth() -> bool:
    password = os.environ.get("WEBAPP_PASSWORD")
    if not password:
        return True
    auth = request.authorization
    return auth is not None and auth.password == password


@app.before_request
def require_auth():
    if not check_auth():
        return Response(
            "Authentication required.",
            401,
            {"WWW-Authenticate": 'Basic realm="es-init"'},
        )


@app.get("/")
def index():
    return render_template("index.html", defaults=DEFAULTS)


@app.post("/run")
def run():
    mode = request.form.get("mode", "download")
    es_host = request.form.get("es_host") or DEFAULTS["es_host"]
    es_port = request.form.get("es_port") or DEFAULTS["es_port"]
    onto_repo = request.form.get("onto_repo") or DEFAULTS["onto_repo"]
    onto_git_tag = request.form.get("onto_git_tag") or DEFAULTS["onto_git_tag"]
    download_filename = request.form.get("download_filename") or DEFAULTS["download_filename"]
    force_reinstall = "true" if request.form.get("force_reinstall") else "false"

    workdir = Path(tempfile.mkdtemp(prefix="es-init-"))

    env = os.environ.copy()
    env.update(
        {
            "ES_HOST": es_host,
            "ES_PORT": es_port,
            "ONTO_REPO": onto_repo,
            "DOWNLOAD_FILENAME": download_filename,
            "FORCE_REINSTALL": force_reinstall,
        }
    )

    if mode == "upload":
        upload = request.files.get("zip_file")
        if not upload or not upload.filename:
            shutil.rmtree(workdir, ignore_errors=True)
            return Response("No file uploaded.\n", status=400)
        mounted_path = workdir / "mounted_onto.zip"
        upload.save(mounted_path)
        env["MOUNTED_FILENAME_OVERRIDE"] = str(mounted_path)
        # ONTO_GIT_TAG isn't needed in mount mode, but clear any leftover value
        # from the parent environment so it can't accidentally steer the script.
        env.pop("ONTO_GIT_TAG", None)
    else:
        if not onto_git_tag:
            shutil.rmtree(workdir, ignore_errors=True)
            return Response("Git tag is required in download mode.\n", status=400)
        env["ONTO_GIT_TAG"] = onto_git_tag

    def generate():
        try:
            process = subprocess.Popen(
                ["bash", str(SCRIPT_PATH)],
                cwd=workdir,
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
            )
            for line in process.stdout:
                yield ANSI_RE.sub("", line)
            process.wait()
            yield f"\n--- finished with exit code {process.returncode} ---\n"
        finally:
            shutil.rmtree(workdir, ignore_errors=True)

    return Response(stream_with_context(generate()), mimetype="text/plain")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
