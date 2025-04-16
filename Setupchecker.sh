export A3SCTL_TOKEN=$(a3sctl auth mtls \
    --api https://127.0.0.1:44443 \
    --api-skip-verify \
    --cert dev/.data/certificates/user-cert.pem \
    --key dev/.data/certificates/user-key.pem \
    --source-name root
    )


a3sctl auth check


a3sctl api delete namespace "/myapp" \
  --api https://127.0.0.1:44443 \
  --api-skip-verify \ || echo "Namespace does not exist. Nothing to delete."


a3sctl api create namespace \
    --api https://127.0.0.1:44443 \
    --api-skip-verify \
    --namespace / \
    --with.name myapp


tg cert --name myca --is-ca


a3sctl api create mtlssource \
 --api https://127.0.0.1:44443 \
 --api-skip-verify \
 --namespace /myapp \
 --with.name my-mtls-source \
 --with.ca "$(cat myca-cert.pem)"


tg cert --name john --signing-cert myca-cert.pem --signing-cert-key myca-key.pem
tg cert --name mike --signing-cert myca-cert.pem --signing-cert-key myca-key.pem


a3sctl api create authorization \
 --api https://127.0.0.1:44443 \
 --api-skip-verify \
 --namespace /myapp \
 --with.name john-access \
 --with.subject '[ ["@source:type=mtls", "@source:name=my-mtls-source", "commonname=john"] ]' \
 --with.permissions '["page1:*", "page2:post", "page3:get"]'


a3sctl api create authorization \
 --api https://127.0.0.1:44443 \
 --api-skip-verify \
 --namespace /myapp \
 --with.name mike-access \
 --with.subject '[ ["@source:type=mtls", "@source:name=my-mtls-source", "commonname=mike"] ]' \
 --with.permissions '["page1:get"]'
