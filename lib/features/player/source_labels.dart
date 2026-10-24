import 'package:flutter/widgets.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/source_mark.dart';

/// The name a source goes by: "Local" for the phone, the volume name for a
/// disk (FR-011.6); null when the disk is not known.
String? sourceName(Disk? disk, AppLocalizations l10n) => switch (disk) {
  null => null,
  Disk(kind: DiskKind.internal) => l10n.sourceLocal,
  Disk(:final label) => label,
};

/// The mark of a source; null for a disk without a mark (FR-012).
Widget? sourceMarkOf(
  Disk? disk,
  TsColors colors, {
  double size = TsSize.sourceMark,
}) => switch (disk) {
  null => null,
  Disk(kind: DiskKind.internal) => SourceMark.local(colors, size: size),
  Disk(markIndex: final index?) => SourceMark.disk(index, colors, size: size),
  Disk() => null,
};
