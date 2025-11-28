i18n = import('i18n')

sh = find_program('sh')
languages = run_command(sh, '-ex', '-c',
    'for i in *.po; do basename "$i" .po; done',
    check: true, capture: true).stdout().strip().split('\n')

assert(languages.length() > 0)
i18n.gettext(original_uuid, languages: languages)
