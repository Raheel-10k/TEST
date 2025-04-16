**Acuvity Setup Guide**

1.  1\. Git Clone
2.  2\. Install dependencies: go, tg, rego, bindata, elegen
3.  3\. Generate development certificates
4.  4\. Build Docker containers
5.  5\. Start Docker Compose in 'cd/dev' directory.
6.  6\. Run make cli command to create a3sctl **custom cli**

**Sample Docker Logs:**

mongo-1  | {"t":{"$date":"2025-04-15T20:48:50.640+00:00"},"s":"I",  "c":"INDEX",    "id":20447,   "ctx":"conn3","msg":"Index build: completed","attr":{"buildUUID":{"uuid":{"$uuid":"90c44d18-aa7c-40c6-9a2b-c395fbd6860d"}}}}

a3s-1    | {"l":"info","t":1744750130.653832,"m":"Root auth initialized","srv":"a3s"}

a3s-1    | {"l":"info","t":1744750130.658802,"m":"JWT info configured","srv":"a3s","iss":"https://127.0.0.1:44443","aud":"https://127.0.0.1:44443"}

a3s-1    | {"l":"info","t":1744750130.6590073,"m":"Announced public API","srv":"a3s","url":"https://127.0.0.1:44443"}

a3s-1    | {"l":"info","t":1744750130.659018,"m":"Cookie policy set","srv":"a3s","policy":"strict"}

a3s-1    | {"l":"info","t":1744750130.6590846,"m":"Cookie domain set","srv":"a3s","domain":"127.0.0.1"}

a3s-1    | {"l":"info","t":1744750130.6897888,"m":"NATS server started","srv":"a3s","url":"tls://127.0.0.1:4222"}

a3s-1    | {"l":"info","t":1744750130.7127771,"m":"Connected to nats","srv":"a3s","server":"tls://127.0.0.1:4222"}

a3s-1    | {"l":"info","t":1744750130.7158437,"m":"Max TCP connections","srv":"a3s","max":0}

a3s-1    | {"l":"info","t":1744750130.7211967,"m":"API server started","srv":"a3s","address":"0.0.0.0:44443"}

**Build CLI Tool**

cd cmd/a3sctl && CGO_ENABLED=0 go install -ldflags="-w -s" -trimpath

**Create Root Token**

a3sctl auth mtls \\

\--api https://127.0.0.1:44443 \\

\--api-skip-verify \\

\--cert dev/.data/certificates/user-cert.pem \\

\--key dev/.data/certificates/user-key.pem \\

\--source-name root

**Create App Namespace**

a3sctl api create namespace \\

\--api https://127.0.0.1:44443 \\

\--api-skip-verify \\

\--namespace / \\

\--with.name myapp

**Generate CA Certificate**

tg cert --name myca --is-ca

**Generate User Certificate**

tg cert --name user1 \\

\--signing-cert myca-cert.pem \\

\--signing-cert-key myca-key.pem

**Create MTLS Source Token**

a3sctl api create mtlssource \\

\--api https://127.0.0.1:44443 \\

\--api-skip-verify \\

\--namespace /myapp \\

\--with.name my-mtls-source \\

\--with.ca "$(cat myca-cert.pem)"

**Generate Certificates for Users**

tg cert --name john --signing-cert myca-cert.pem --signing-cert-key myca-key.pem

tg cert --name mike --signing-cert myca-cert.pem --signing-cert-key myca-key.pem

**Create Authorization for John**

a3sctl api create authorization \\

\--api https://127.0.0.1:44443 \\

\--api-skip-verify \\

\--namespace /myapp \\

\--with.name john-access \\

\--with.subject '\[ \["@source:type=mtls", "@source:name=my-mtls-source", "commonname=john"\] \]' \\

\--with.permissions '\["page1:\*", "page2:post", "page3:get"\]'

**Create Authorization for Mike**

a3sctl api create authorization \\

\--api https://127.0.0.1:44443 \\

\--api-skip-verify \\

\--namespace /myapp \\

\--with.name mike-access \\

\--with.subject '\[ \["@source:type=mtls", "@source:name=my-mtls-source", "commonname=mike"\] \]' \\

\--with.permissions '\["page1:get"\]'

**Obtain Token for John**

a3sctl auth mtls \\

\--api https://127.0.0.1:44443 \\

\--api-skip-verify \\

\--source-name my-mtls-source \\

\--source-namespace /myapp \\

\--cert john-cert.pem \\

\--key john-key.pem

export JOHN=<John-token>

**Obtain Token for Mike**

a3sctl auth mtls \\

\--api https://127.0.0.1:44443 \\

\--api-skip-verify \\

\--source-name my-mtls-source \\

\--source-namespace /myapp \\

\--cert mike-cert.pem \\

\--key mike-key.pem

export MIKE=<Mike-token>

**Test Case 1: Mike accesses 'page1' with GET**

curl -k -v -H "Content-Type: application/json" \\

\-d "{

\\"token\\": \\"$MIKE\\",

\\"resource\\": \\"page1\\",

\\"action\\": \\"get\\",

\\"namespace\\": \\"/myapp\\"

}" \\

https://127.0.0.1:44443/authz

**Test Case 2: Mike accesses 'page2' with GET (Unauthorized)**

curl -k -v -H "Content-Type: application/json" \\

\-d "{

\\"token\\": \\"$MIKE\\",

\\"resource\\": \\"page2\\",

\\"action\\": \\"get\\",

\\"namespace\\": \\"/myapp\\"

}" \\

https://127.0.0.1:44443/authz
