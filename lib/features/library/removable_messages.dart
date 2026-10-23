import 'package:tuneshell/features/library/removable_controller.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';

/// The words of a one-time message of the removable disks (UC-003).
String removableMessageText(AppLocalizations l10n, RemovableMessage message) =>
    switch (message) {
      RemovableMessage.noAudio => l10n.removableNoAudio,
      RemovableMessage.addFailed => l10n.removableAddFailed,
      RemovableMessage.notRemovable => l10n.removableNotRemovable,
      RemovableMessage.refreshFailed => l10n.removableRefreshFailed,
    };
