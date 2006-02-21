#!/bin/bash

### jadetex ###

cd ${SRC}
LOG=jadetex-blfs.log

unpack_tarball jadetex-${JADETEX_VER}
cd ${PKGDIR}

max_log_init jadetex ${JADETEX_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
(
sed -i.orig -e "s/original texmf.cnf/modified texmf.cnf/" \
            -e "s/memory hog.../&\npool_size.context = 750000/" \
    $(kpsewhich texmf.cnf)
cat >> $(kpsewhich texmf.cnf) << "EOF"

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

LATEX_FMT_DIR="$(kpsewhich -expand-var '$TEXMFSYSVAR')/web2c" &&
mv -v $(kpsewhich latex.fmt) $(kpsewhich latex.fmt).orig &&
mv -v ${LATEX_FMT_DIR}/latex.log ${LATEX_FMT_DIR}/latex.log.orig &&
fmtutil-sys --byfmt latex
) >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS} &&
(
install -v -m755 -d \
    $(kpsewhich -expand-var '$TEXMFLOCAL')/tex/jadetex/config &&
install -v -m644 dsssl.def jadetex.ltx \
    $(kpsewhich -expand-var '$TEXMFLOCAL')/tex/jadetex &&
install -v -m644 {,pdf}jadetex.ini \
    $(kpsewhich -expand-var '$TEXMFLOCAL')/tex/jadetex/config &&
FMTUTIL_CNF="$(kpsewhich fmtutil.cnf)" &&
mv ${FMTUTIL_CNF} ${FMTUTIL_CNF}.orig &&

cat ${FMTUTIL_CNF}.orig - >> ${FMTUTIL_CNF} << "EOF"

# JadeTeX formats:
jadetex		etex		-		"&latex"     jadetex.ini
pdfjadetex	pdfetex		-		"&pdflatex"  pdfjadetex.ini

EOF
mv -v $(kpsewhich -expand-var '$TEXMFMAIN')/ls-R \
      $(kpsewhich -expand-var '$TEXMFMAIN')/ls-R.orig &&
mv -v $(kpsewhich -expand-var '$TEXMFSYSVAR')/ls-R \
      $(kpsewhich -expand-var '$TEXMFSYSVAR')/ls-R.orig &&

mktexlsr &&
fmtutil-sys --byfmt jadetex &&
fmtutil-sys --byfmt pdfjadetex &&
mktexlsr &&
ln -v -sf etex /usr/bin/jadetex &&
ln -v -sf pdfetex /usr/bin/pdfjadetex
) >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

