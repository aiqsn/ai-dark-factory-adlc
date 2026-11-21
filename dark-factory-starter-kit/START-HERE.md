# Dark Factory Starter Kit

Two repositories that go with the guide "Dark Factory ADLC on a Shoestring Budget":

- `dark-factory-starter/`: your **public** factory repo. Start with its README.md.
- `dark-factory-starter-scenarios/`: your **private** hidden-scenarios repo. Name it `<factory-repo>-scenarios`.

The full guide is in `dark-factory-starter/docs/guide.html`. A 22-slide version is in `dark-factory-starter/docs/slides.html`.

Deploys go to Cloudflare Workers by default. Ready-made alternatives for AWS Lambda, Google Cloud Run and Azure Container Apps are in `dark-factory-starter/.github/workflows-optional/`; the README's "Other deployment targets" explains how to switch.

Quick local check:

    cd dark-factory-starter
    make install && make test
    make dev                     # then, in another terminal: make probe
