local architectures = ["amd64","arm64"];

local image_name = "spamassassin";

local github_repo_name = "container-spamassassin";
local github_desc = "Container for runnung spamassassin/spamd";
local url = "https://gitea.federationhq.de/Container/spamassassin";

local version_4_0_1 = 
{
    tag: "4.0.1",
    additional_tags: ["4.0","4"],
    dir: ".",

};


local versions = [version_4_0_1];


local build_steps(versions,arch) = [
    {
        name: "Build " + version.tag,
        image: "quay.io/buildah/stable",
        privileged: true,
        volumes:
        [
        {
            name: "fedhq-ca-crt",
            path: "/etc/ssl/certs2/"

        }
        ],
        commands: [
            "scripts/setupEnvironment.sh",
            "cd " + version.dir + ";" + 'buildah bud --network host -t "registry.cloud.federationhq.de/' + image_name + ':' +version.tag + "-" + arch + '" --arch ' + arch,
            'buildah push --all registry.cloud.federationhq.de/'+ image_name+':'+version.tag + "-" + arch

        ]
    }
    for version in versions
];

local build_pipelines(architectures) = [
    {
        kind: "pipeline",
        type: "kubernetes",
        name: "build-"+arch,
        platform: {
            arch: arch
        },
        volumes:
            [
                {
                    name: "fedhq-ca-crt",
                    config_map:
                    {
                        name: "fedhq-ca-crt",
                        default_mode: 420,
                        optional: false
                    },

                }
            ],
        node_selector:
        {
            'kubernetes.io/arch': arch,
            'federationhq.de/compute': true
        },
        steps: build_steps(versions, arch),
    }
    for arch in architectures
];



local push_pipelines(versions, architectures) = [
    {
        kind: "pipeline",
        type: "kubernetes",
        name: "push-"+version.tag,
        platform: {
            arch: "amd64"
        },
        volumes:
            [
                {
                    name: "fedhq-ca-crt",
                    config_map:
                    {
                        name: "fedhq-ca-crt",
                        default_mode: 420,
                        optional: false
                    },

                }
            ],
        node_selector:
        {
            'kubernetes.io/arch': "amd64",
            'federationhq.de/compute': true
        },
        depends_on: [
            "build-"+arch
            for arch in architectures
        ],
        steps:
            [   
                {
                    name: "Push " + version.tag,
                    image: "quay.io/buildah/stable",
                    privileged: true,
                    environment:
                        {
                            USERNAME: 
                            {
                                from_secret: "username"
                            },
                            PASSWORD:
                            {
                                from_secret: "password"
                            }
                        },
                    volumes:
                    [
                        {
                            name: "fedhq-ca-crt",
                            path: "/etc/ssl/certs2/"

                        }
                    ],
                    commands:
                    [
                        "scripts/setupEnvironment.sh",
                        "buildah manifest create " + image_name + ":"+version.tag,
                    ]
                    +
                    [
                    "buildah manifest add " + image_name + ":" + version.tag + " registry.cloud.federationhq.de/" + image_name + ":"+version.tag + "-" + arch 
                    for arch in architectures
                    ]
                    +
                    [
                        "buildah manifest push --all " + image_name +":"+version.tag + " docker://registry.cloud.federationhq.de/" + image_name +":"+tag
                        for tag in [version.tag]+version.additional_tags
                    ]
                    +
                    [
                        "buildah login -u $${USERNAME} -p $${PASSWORD} registry.hub.docker.com",
                    ]
                    +
                    [
                        "buildah manifest push --all " + image_name + ":"+version.tag + " docker://registry.hub.docker.com/byterazor/" + image_name +":"+tag
                        for tag in [version.tag]+version.additional_tags
                    ]
                }
            ]
        }
        for version in versions
];

local upload_readme = {
    kind: "pipeline",
    type: "kubernetes",
    name: "upload-readme",
    node_selector: {
        "kubernetes.io/arch": "amd64",
        "federationhq.de/location": "Blumendorf",
        "federationhq.de/compute": true
    },
    steps: [
        {
            name: "push readme",
            image: "byterazor/drone-docker-readme-push:latest",
            pull: "always",
            settings: {
                REPOSITORY_NAME: "byterazor/" + image_name,
                FILENAME: "README.md",
                USERNAME: {
                    from_secret: "username"
                },
                PASSWORD: {
                    from_secret: "password"
                },
            }
        }
    ],
    depends_on:
    [
        "push-"+version.tag
            for version in versions
    ]
};


local push_github = {
    kind: "pipeline",
    type: "kubernetes",
    name: "mirror-to-github",
    node_selector: {
        "kubernetes.io/arch": "amd64",
        "federationhq.de/location": "Blumendorf",
        "federationhq.de/compute": true
    },
    steps: [
        {
            name: "github-mirror",
            image: "registry.cloud.federationhq.de/drone-github-mirror:latest",
            pull: "always",
            settings: {
                GH_TOKEN: {
                    from_secret: "GH_TOKEN"
                },
                GH_REPO: "byterazor/" + github_repo_name,
                GH_REPO_DESC: github_desc,
                GH_REPO_HOMEPAGE: url
            }
        }
    ],
    depends_on:
    [
        "push-"+version.tag
            for version in versions
    ]
};



build_pipelines(architectures) + push_pipelines(versions,architectures) + [upload_readme] + [push_github] +
    [
{
    kind: "secret",
    name: "GH_TOKEN",
    get:{
        path: "github",
        name: "token"
    }
},
{
    kind: "secret",
    name: "username",
    get:{
        path: "docker",
        name: "username"
    }
},
{
    kind: "secret",
    name: "password",
    get:{
        path: "docker",
        name: "secret"
    }
}
    ]
