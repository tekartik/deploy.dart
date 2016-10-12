# tekartik_deploy.dart

File deployment helper (file system, google storage)



## Usage

Google Cloud Storage web deploy

    gswebdeploy <local_src> <gs://bucket/path>
    
local dir deploy

    dirdeploy

Google Cloud Storage deploy

    gsdeploy


## deploy.yaml

For dirdeploy

    files:
    - file_to_include
      file_to_include2: new_file_name
    exclude:
      file_or_dir_to exclude

## Activation

### From git repository

    pub global activate -s git git://github.com/tekartik/tekartik_deploy.dart

### From local path

    pub global activate -s path .

