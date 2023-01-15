#!/bin/sh

set +ex
CC=gcc

export HOME=/root 
export TERM=xterm-256color 
export PS1='(lfs chroot) \u:\w\$ ' 
export PATH=/usr/bin:/usr/sbin

cd /packages

tar -xvf lynx2.tar.bz2
cd lynx2.8.9rel.1
patch -p1 -i ../lynx-2.8.9rel.1-security_fix-1.patch
./configure --prefix=/usr          \
            --sysconfdir=/etc/lynx \
            --datadir=/usr/share/doc/lynx-2.8.9rel.1 \
            --with-zlib            \
            --with-bzlib           \
            --with-ssl             \
            --with-screen=ncursesw \
            --enable-locale-charset &&
make -j$(nproc)
make install-full -j$(nproc) &&
chgrp -v -R root /usr/share/doc/lynx-2.8.9rel.1/lynx_doc
sed -e '/#LOCALE/     a LOCALE_CHARSET:TRUE'     \
    -i /etc/lynx/lynx.cfg
sed -e '/#PERSIST/    a PERSISTENT_COOKIES:TRUE' \
    -i /etc/lynx/lynx.cfg
cd ..
rm -rf lynx2.8.9rel.1

tar -xvf gpm.tar.bz2
cd gpm-1.20.7
patch -Np1 -i ../gpm-1.20.7-consolidated-1.patch
./autogen.sh
./configure --prefix=/usr --sysconfdir=/etc
make -j$(nproc)
make install -j$(nproc)
rm -fv /usr/lib/libgpm.a
ln -sfv libgpm.so.2.1.0 /usr/lib/libgpm.so 
install -v -m644 conf/gpm-root.conf /etc
make install-gpm -j$(nproc)
cd ..
rm -rf gpm-1.20.7

tar -xvf openssh.tar.gz
cd openssh-9.0p1
install  -v -m700 -d /var/lib/sshd
chown    -v root:sys /var/lib/sshd
groupadd -g 50 sshd
useradd  -c 'sshd PrivSep' \
         -d /var/lib/sshd  \
         -g sshd           \
         -s /bin/false     \
         -u 50 sshd
./configure --prefix=/usr                            \
            --sysconfdir=/etc/ssh                    \
            --with-privsep-path=/var/lib/sshd        \
            --with-default-path=/usr/bin             \
            --with-superuser-path=/usr/sbin:/usr/bin \
            --with-pid-dir=/run
make -j$(nproc)
make install -j$(nproc)
install -v -m755    contrib/ssh-copy-id /usr/bin
make install-sshd -j$(nproc)
cd ..
rm -rf openssh-9.0p1

tar -xvf p11-kit.tar.xz
cd p11-kit-0.24.1
sed '20,$ d' -i trust/trust-extract-compat &&
cat >> trust/trust-extract-compat << "EOF"
# Copy existing anchor modifications to /etc/ssl/local
/usr/libexec/make-ca/copy-trust-modifications

# Update trust stores
/usr/sbin/make-ca -r
EOF
mkdir p11-build && cd p11-build
meson --prefix=/usr       \
      --buildtype=release \
      -Dtrust_paths=/etc/pki/anchors
ninja
ninja install
ln -sfv /usr/libexec/p11-kit/trust-extract-compat \
        /usr/bin/update-ca-certificates
ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so
cd ../..
rm -rf p11-kit-0.24.1

tar -xvf libtasn1.tar.gz
cd libtasn1-4.18.0
./configure --prefix=/usr --disable-static
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf libtasn1-4.18.0

tar -xvf make-ca.tar.xz
cd make-ca-1.10
make install
install -vdm755 /etc/ssl/local
/usr/sbin/make-ca -g
systemctl enable update-pki.timer
cd ..
rm -rf make-ca-1.10

tar -xvf wget.tar.gz
cd wget-1.21.3
./configure --prefix=/usr      \
            --sysconfdir=/etc  \
            --with-ssl=openssl
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf wget-1.21.3

tar -xvf zsh.tar.xz
cd zsh-5.9
./configure --prefix=/usr            \
            --sysconfdir=/etc/zsh    \
            --enable-etcdir=/etc/zsh \
            --enable-cap             \
            --enable-gdbm
make -j$(nproc)
make install -j$(nproc)
cat >> /etc/shells << "EOF"
/bin/zsh
EOF
cd ..
rm -rf zsh-5.9

tar -xvf nano.tar.xz
cd nano-6.4
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --enable-utf8     \
            --docdir=/usr/share/doc/nano-6.4
make -j$(nproc)
make install -j$(nproc)
cat > /etc/nanorc << EOF
set autoindent
set constantshow
set fill 72
set historylog
set multibuffer
set nohelp
set positionlog
set quickblank
set regexp
EOF
cd ..
rm -rf nano-6.4

#tar -xvf sudo.tar.gz
#cd sudo-1.9.11p3
#./configure --prefix=/usr              \
#            --libexecdir=/usr/lib      \
#            --with-secure-path         \
#            --with-all-insults         \
#            --with-env-editor          \
#            --docdir=/usr/share/doc/sudo-1.9.11p3 \
#            --with-passprompt="[sudo] password for %p: "
#make -j$(nproc)
#make install -j$(nproc)
#ln -sfv libsudo_util.so.0.0.0 /usr/lib/sudo/libsudo_util.so.0
#cat > /etc/sudoers.d/00-sudo << "EOF"
#Defaults secure_path="/usr/sbin:/usr/bin"
#%wheel ALL=(ALL) ALL
#EOF
#cd ..
#rm -rf sudo-1.9.11p3

set -ex