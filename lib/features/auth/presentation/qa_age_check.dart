import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../skills/presentation/skill_ui.dart';

/// Loopback QA entry check. The entered age stays in the dialog.
Future<bool> confirmQaAdultEntry(BuildContext context, String language) async {
  var age = '';
  var guardianRequired = false;
  return await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, update) {
            final value = int.tryParse(age);
            final validAge = value != null && value >= 5 && value <= 100;
            return AlertDialog(
              scrollable: true,
              title: Text(
                guardianRequired
                    ? str3(
                        language,
                        'Ota-ona tasdig‘i kerak',
                        'Нужно подтверждение родителя',
                        'Guardian verification required',
                      )
                    : str3(
                        language,
                        'Yoshingizni kiriting',
                        'Укажите ваш возраст',
                        'Enter your age',
                      ),
              ),
              content: guardianRequired
                  ? Text(
                      str3(
                        language,
                        'Ota-ona tasdiqlashi tayyor bo‘lganda yangi akkaunt ochish mumkin bo‘ladi.',
                        'Создание нового аккаунта станет доступно после подтверждения родителя.',
                        'New account setup requires verified guardian approval.',
                      ),
                    )
                  : TextField(
                      key: const ValueKey('qa_entry_age'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      decoration: InputDecoration(
                        labelText: str3(language, 'Yosh', 'Возраст', 'Age'),
                      ),
                      onChanged: (text) => update(() => age = text),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(str3(language, 'Yopish', 'Закрыть', 'Close')),
                ),
                if (!guardianRequired)
                  FilledButton(
                    key: const ValueKey('qa_entry_age_continue'),
                    onPressed: !validAge
                        ? null
                        : () {
                            // The internal QA cohort is adult-only for new
                            // accounts until a real guardian verifier is wired.
                            if (value >= 18) {
                              Navigator.of(context).pop(true);
                            } else {
                              update(() => guardianRequired = true);
                            }
                          },
                    child: Text(
                      str3(language, 'Davom etish', 'Продолжить', 'Continue'),
                    ),
                  ),
              ],
            );
          },
        ),
      ) ??
      false;
}
