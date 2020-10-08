# $ cd pyanjay
# $ docker build -f docker/Dockerfile .

FROM python:3.8 AS wheelbuilder
RUN apt-get update && apt-get install -y libmbedtls-dev
COPY . /
RUN python3 setup.py bdist_wheel

FROM python:3.8
STOPSIGNAL SIGINT
RUN apt-get update && apt-get install -y libmbedtls-dev
COPY --from=wheelbuilder /dist/pyanjay-*-linux_x86_64.whl .
RUN python3 -m pip install ./pyanjay-*-linux_x86_64.whl
CMD python3 -m pyanjay -l DEBUG -n 1
