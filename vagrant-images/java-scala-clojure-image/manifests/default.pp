include java

include apt

apt::source { "sbt_source":
  location => 'https://dl.bintray.com/sbt/debian',
  release => '',
  repos => '/',
  key => { 'id' => '2EE0EA64E40A89B84B2DF73499E82A75642AC823',
   'server' => 'keyserver.ubuntu.com' },
}

package { "sbt":
  ensure => 'installed',
  require => Apt::Source['sbt_source'],
}

package { "scala":
  ensure => 'installed',
}

package { "ant":
  ensure => 'installed',
}

package { "leiningen":
  ensure => 'installed',
}

include apt

apt::ppa { "ppa:plt/racket":
}

package { "racket":
  ensure => 'installed',
  require => Apt::Ppa['ppa:plt/racket'],
}

package { "clang":
  ensure => 'installed',
}

package { "nasm":
  ensure => 'installed',
}

package { "gcc-multilib":
  ensure => 'installed',
}

package { "make":
  ensure => 'installed',
}

