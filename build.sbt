import sbt.Keys.publishMavenStyle

name := "sbt-protoc"

resolvers += "internal.repo.read" at "https://nexus.whisk-dev.com/repository/whisk-maven-group/"

description := "SBT plugin for generating code from Protocol Buffer using protoc"

scalacOptions := Seq("-deprecation", "-unchecked", "-Xlint", "-Yno-adapted-args")

scalacOptions += "-release:8"

scalaVersion := "2.12.20"

addSbtPlugin("org.portable-scala" % "sbt-platform-deps" % "1.0.1")

libraryDependencies ++= Seq(
  "com.thesamet.scalapb" %% "protoc-bridge" % "0.9.7"
)

enablePlugins(SbtPlugin)

scriptedBufferLog := false

scriptedLaunchOpts += s"-Dplugin.version=${version.value}"

// https://github.com/sbt/sbt/issues/5049#issuecomment-538404839
pluginCrossBuild / sbtVersion := "1.2.8"

sonatypeProfileName := "com.thesamet"

inThisBuild(
  List(
    organization := "com.thesamet",
    homepage     := Some(url("https://github.com/thesamet/sbt-protoc")),
    licenses := List(
      "Apache-2.0" ->
        url("http://www.apache.org/licenses/LICENSE-2.0")
    ),
    developers := List(
      Developer(
        "thesamet",
        "Nadav Samet",
        "thesamet@gmail.com",
        url("https://www.thesamet.com")
      )
    ),
    scmInfo := Some(
      ScmInfo(
        url("https://github.com/whisklabs/sbt-protoc"),
        "scm:git:github.com/whisklabs/sbt-protoc.git"
      )
    ),
    publishMavenStyle := true,
    credentials += Credentials(Path.userHome / ".m2" / ".credentials"),
    publishTo := Some("internal.repo" at "https://nexus.whisk-dev.com/repository/whisk-maven2/")
  )
)
