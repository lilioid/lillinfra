FROM docker.io/netboxcommunity/netbox:v4.2

RUN echo "netbox-qrcode>=0.0.13" >> /opt/netbox/local_requirements.txt &&\
    /opt/netbox/venv/bin/pip install -r /opt/netbox/local_requirements.txt
