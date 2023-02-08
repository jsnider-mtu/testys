FROM python:3.10.5-alpine3.16 as builder

RUN set -ex; \
apk add --no-cache \
git unzip groff build-base libffi-dev cmake bash curl openssl

RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq && chmod +x /usr/local/bin/yq

RUN set -eux; \
git clone --single-branch --depth 1 -b 2.9.21 https://github.com/aws/aws-cli.git; \
cd /aws-cli; \
sed -i'' 's/PyInstaller.*/PyInstaller==5.2/g' requirements-build.txt; \
python -m venv venv; \
. venv/bin/activate; \
./scripts/installers/make-exe

RUN set -ex; \
unzip /aws-cli/dist/awscli-exe.zip; \
./aws/install --bin-dir /aws-cli-bin; \
/aws-cli-bin/aws --version

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
chmod +x kubectl && mv kubectl /usr/local/bin/kubectl

RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

FROM python:3.10.5-alpine3.16

COPY --from=builder /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=builder /aws-cli-bin/ /usr/local/bin/
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/helm /usr/local/bin/helm
COPY --from=builder /usr/local/bin/yq /usr/local/bin/yq

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
