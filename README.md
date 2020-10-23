# docker knative install openshift

## Scope

A simple docker container that has everything required for knative serverless to run on OpenShift 4.x on the IBM Cloud.

## Usage

Run via a `docker` `ENTRYPOINT` check: <https://phoenixnap.com/kb/docker-cmd-vs-entrypoint> if you are wondering why.

**EXAMPLE**:
```bash
docker run --entrypoint /scripts/run.sh quay.io/ibm-advocados/openshift-cli-base:4.5 "APIKEY" "CLUSTER"
```

## License & Authors

If you would like to see the detailed LICENSE click [here](./LICENSE).

- Author: David Carew <carew@us.ibm.com>
- Author: JJ Asghar <awesome@ibm.com>

```text
Copyright:: 2020- IBM, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
