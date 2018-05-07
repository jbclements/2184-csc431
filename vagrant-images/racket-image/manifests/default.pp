include apt

apt::ppa { "ppa:plt/racket":
}

package { "racket":
  ensure => 'installed',
  require => Apt::Ppa['ppa:plt/racket'],
}

class { "java":
  distribution => 'jre',
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

