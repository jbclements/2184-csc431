include java

package { "clang" :
  ensure => 'installed',
}

package { "nasm":
  ensure => 'installed',
}

package { "ant":
  ensure => 'installed',
}
