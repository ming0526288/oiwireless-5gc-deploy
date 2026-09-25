# OIWireless 5GC Docker images

These archives contain the five Docker images required by
`docker-compose-5gc.yaml`. They are stored with Git LFS.

Install Git LFS before cloning:

```bash
sudo apt update
sudo apt install -y git-lfs
git lfs install
```

After cloning, verify that the LFS objects were downloaded:

```bash
cd ~/oiwireless/oiwireless-5gc-deploy
git lfs pull
git lfs ls-files
sha256sum -c docker-images/SHA256SUMS
```

Load all images:

```bash
for archive in docker-images/*.tar.gz; do
  gzip -dc "$archive" | docker load
done
```

The following image tags are included:

- `oiwireless-amf:v1.5.2`
- `oiwireless-smf:v1.5.2`
- `oiwireless-upf:v1.5.2`
- `mysql:5.7.2`
- `phpmyadmin:latest`

