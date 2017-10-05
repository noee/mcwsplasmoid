import qbs

Project {
    minimumQbsVersion: "1.7.1"
    name: "MCWS Plasmoid"
    Application {

        files: [
            "plasmoid/metadata.desktop",
            "README.md",
            "plasmoid/**/*.qml",
            "plasmoid/**/*.js",
            "plasmoid/**/*.xml"
        ]

        Group {     // Properties for the produced executable
            fileTagsFilter: product.type
            qbs.install: true
        }
    }
}
