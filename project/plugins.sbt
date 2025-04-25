libraryDependencies += "org.scala-sbt" %% "scripted-plugin" % sbtVersion.value

addSbtPlugin("org.scalameta" % "sbt-scalafmt" % "2.5.4")

credentials += Credentials(Path.userHome / ".m2" / ".credentials")
resolvers += "internal.repo.read" at "https://nexus.whisk-dev.com/repository/whisk-maven-group/"
addSbtPlugin("com.whisk" % "whisk-sbt-plugin" % "2025.04.09-3153")
