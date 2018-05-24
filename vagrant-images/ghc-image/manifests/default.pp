include java

package { "haskell-platform":
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

