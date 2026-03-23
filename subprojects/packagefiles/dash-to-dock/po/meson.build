i18n = import('i18n')

sh = find_program('sh')
languages = run_command(sh, '-ex', '-c',
    'for i in *.po; do basename "$i" .po; done',
    check: true, capture: true).stdout().strip().split('\n')

gettext_domain = run_command(jq, '-r', '."gettext-domain"', metadata).stdout().strip()

assert(languages.length() > 0)
i18n.gettext(gettext_domain,
    args: [
        '--keyword=__',
        '--keyword=N__',
        '--from-code=utf-8',
        '--add-comments=Translators:',
    ],
    install: false,
    languages: languages,
)
