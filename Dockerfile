FROM python:3-alpine as builder

WORKDIR /usr/src/app

ENV DATAROOTDIR /usr/share
ENV SYSCONFDIR /etc
ENV AD_LOGIN administrator
ENV PASSWORD password

RUN apk add --no-cache libldap && \
    apk add --no-cache --virtual build-dependencies build-base yaml-dev openldap-dev

COPY requirements.txt requirements.txt
RUN pip3 wheel -r requirements.txt --wheel-dir=/build/wheels

COPY . /usr/src/app
RUN python setup.py bdist_wheel -d /build/wheels

FROM python:3-alpine as production

RUN apk add --no-cache libldap

COPY --from=builder /build/wheels /tmp/wheels
RUN pip3 install \
  --force-reinstall \
  --ignore-installed \
  --upgrade \
  --no-index \
  --no-deps /tmp/wheels/* \
 && rm -rf /tmp/wheels \
 && adduser -S ldapcherry

COPY --from=builder /usr/src/app/conf /etc/ldapcherry
COPY --from=builder /usr/src/app/resources/templates/ /usr/share/ldapcherry/templates/
COPY --from=builder /usr/src/app/resources/static /usr/share/ldapcherry/static/ 
#/usr/local/lib/python3.8/site-packages/usr/share/ldapcherry/
USER ldapcherry

CMD ["ldapcherryd", "-c", "/etc/ldapcherry/ldapcherry.ini"]