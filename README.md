# tekartik_deploy.dart

File deployment helper (file system, google storage)



## Usage

local dir deploy

    dirdeploy


## deploy.yaml


    files:
    - file_to_include
    exclude:
     file_or_dir_to exclude

## Activation

### From git repository

    pub global activate -s git git://github.com/tekartik/tekartik_deploy.dart

### From local path

    pub global activate -s path .

