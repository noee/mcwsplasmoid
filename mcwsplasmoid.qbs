import qbs

Project {
    minimumQbsVersion: "1.7.1"
    name: "MCWS Plasmoid"
    Application {

        files: [
            "plasmoid/metadata.desktop",
            "*.md",
            "plasmoid/**/*.qml",
            "plasmoid/**/*.*js",
            "plasmoid/**/*.xml",
            "plasmoid/**/*.png"
        ]
    }
}
