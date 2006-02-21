#!/bin/bash

### jadetex ###

cd ${SRC}
LOG=jadetex-blfs.log

unpack_tarball jadetex-${JADETEX_VER}
cd ${PKGDIR}

max_log_init jadetex ${JADETEX_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
sed -i.orig -e "s/original texmf.cnf/modified texmf.cnf/" \
   /usr/share/texmf/web2c/texmf.cnf
# TODO: This needs to be added below "ConTeXt is a memory hog" in
#       /usr/share/texmf/web2c/texmf.cnf
#pool_size.context = 750000
cat >> /usr/share/texmf/web2c/texmf.cnf << "EOF"

% The following 3 sections added for JadeTeX

% latex settings
main_memory.latex = 1100000
param_size.latex = 1500
stack_size.latex = 1500
hash_extra.latex = 15000
string_vacancies.latex = 45000
pool_free.latex = 47500
nest_size.latex = 500
save_size.latex = 5000
pool_size.latex = 500000
max_strings.latex = 55000
font_mem_size.latex= 400000

% jadetex settings
main_memory.jadetex = 1500000
param_size.jadetex = 1500
stack_size.jadetex = 1500
hash_extra.jadetex = 50000
string_vacancies.jadetex = 45000
pool_free.jadetex = 47500
nest_size.jadetex = 500
save_size.jadetex = 5000
pool_size.jadetex = 500000
max_strings.jadetex = 55000

% pdfjadetex settings
main_memory.pdfjadetex = 2500000
param_size.pdfjadetex = 1500
stack_size.pdfjadetex = 1500
hash_extra.pdfjadetex = 50000
string_vacancies.pdfjadetex = 45000
pool_free.pdfjadetex = 47500
nest_size.pdfjadetex = 500
save_size.pdfjadetex = 5000
pool_size.pdfjadetex = 500000
max_strings.pdfjadetex = 55000
EOF

cp -R /usr/share/texmf/tex/latex/config . &&
cd config &&
tex -ini -progname=latex latex.ini &&
mv /usr/share/texmf/web2c/latex.fmt \
   /usr/share/texmf/web2c/latex.fmt.orig &&
install -m 644 latex.fmt /usr/share/texmf/web2c &&
cd ..

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

ln -sf tex /usr/bin/jadetex &&
ln -sf pdftex /usr/bin/pdfjadetex &&
mktexlsr

