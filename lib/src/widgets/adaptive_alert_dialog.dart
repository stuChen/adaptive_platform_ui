import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../platform/platform_info.dart';
import 'ios26/ios26_alert_dialog.dart';

export 'ios26/ios26_alert_dialog.dart' show AlertAction, AlertActionStyle;

/// Configuration for text input in alert dialog
class AdaptiveAlertDialogInput {
  /// Creates a text input configuration for alert dialog
  const AdaptiveAlertDialogInput({
    required this.placeholder,
    this.initialValue,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
  });

  /// Placeholder text for the text field
  final String placeholder;

  /// Initial value for the text field
  final String? initialValue;

  /// Keyboard type for the text field
  final TextInputType? keyboardType;

  /// Whether to obscure the text (for passwords)
  final bool obscureText;

  /// Maximum length of the text input
  final int? maxLength;
}

class _AdaptiveAlertIconSource {
  const _AdaptiveAlertIconSource({
    this.iconData,
    this.symbolName,
    this.imageProvider,
    this.widget,
    this.assetPath,
    this.assetPackage,
    this.filePath,
    this.networkUrl,
  });

  final IconData? iconData;
  final String? symbolName;
  final ImageProvider? imageProvider;
  final Widget? widget;
  final String? assetPath;
  final String? assetPackage;
  final String? filePath;
  final String? networkUrl;

  bool get hasVisual =>
      iconData != null ||
      symbolName != null ||
      imageProvider != null ||
      widget != null ||
      assetPath != null ||
      filePath != null ||
      networkUrl != null;
}

/// An adaptive alert dialog that renders platform-specific styles
///
/// On iOS 26+: Uses native iOS 26 UIAlertController with Liquid Glass
/// On iOS <26 (iOS 18 and below): Uses CupertinoAlertDialog
/// On Android: Uses Material AlertDialog
class AdaptiveAlertDialog {
  AdaptiveAlertDialog._();

  static _AdaptiveAlertIconSource _resolveIconSource({
    required dynamic icon,
    String? iconAsset,
    String? assetPackage,
  }) {
    if (iconAsset != null) {
      return _AdaptiveAlertIconSource(
        imageProvider: AssetImage(iconAsset, package: assetPackage),
        assetPath: iconAsset,
        assetPackage: assetPackage,
      );
    }

    if (icon is ImageIcon) {
      return _resolveIconSource(icon: icon.image);
    }

    if (icon is AssetImage) {
      return _AdaptiveAlertIconSource(
        imageProvider: icon,
        assetPath: icon.assetName,
      );
    }

    if (icon is FileImage) {
      return _AdaptiveAlertIconSource(
        imageProvider: icon,
        filePath: icon.file.path,
      );
    }

    if (icon is NetworkImage) {
      return _AdaptiveAlertIconSource(
        imageProvider: icon,
        networkUrl: icon.url,
      );
    }

    if (icon is ImageProvider) {
      return _AdaptiveAlertIconSource(imageProvider: icon);
    }

    if (icon is Widget) {
      return _AdaptiveAlertIconSource(widget: icon);
    }

    if (icon is String) {
      if (icon.contains('/')) {
        return _AdaptiveAlertIconSource(
          imageProvider: AssetImage(icon, package: assetPackage),
          assetPath: icon,
          assetPackage: assetPackage,
        );
      }
      return _AdaptiveAlertIconSource(symbolName: icon);
    }

    if (icon is IconData) {
      return _AdaptiveAlertIconSource(iconData: icon);
    }

    return const _AdaptiveAlertIconSource();
  }

  static Widget _buildAlertIconWidget(
    _AdaptiveAlertIconSource source, {
    required TargetPlatform platform,
    double? size,
    Color? color,
  }) {
    final dimension = size ?? 40;

    if (source.widget != null) {
      return SizedBox(
        width: dimension,
        height: dimension,
        child: source.widget,
      );
    }

    if (source.imageProvider != null) {
      return SizedBox(
        width: dimension,
        height: dimension,
        child: Image(
          image: source.imageProvider!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            platform == TargetPlatform.iOS
                ? CupertinoIcons.photo
                : Icons.image_not_supported,
            size: dimension,
            color: color,
          ),
        ),
      );
    }

    if (source.iconData != null) {
      return Icon(source.iconData, size: dimension, color: color);
    }

    if (source.symbolName != null) {
      final iconData = platform == TargetPlatform.iOS
          ? _sfSymbolToCupertinoIcon(source.symbolName!)
          : Icons.circle;
      return Icon(iconData, size: dimension, color: color);
    }

    return SizedBox.square(dimension: dimension);
  }

  static IconData _sfSymbolToCupertinoIcon(String sfSymbol) {
    const iconMap = {
      'checkmark.circle': CupertinoIcons.checkmark_circle,
      'checkmark.circle.fill': CupertinoIcons.checkmark_alt_circle_fill,
      'xmark.circle': CupertinoIcons.xmark_circle,
      'xmark.circle.fill': CupertinoIcons.xmark_circle_fill,
      'exclamationmark.triangle': CupertinoIcons.exclamationmark_triangle,
      'exclamationmark.triangle.fill':
          CupertinoIcons.exclamationmark_triangle_fill,
      'info.circle': CupertinoIcons.info_circle,
      'info.circle.fill': CupertinoIcons.info_circle_fill,
      'trash': CupertinoIcons.trash,
      'trash.fill': CupertinoIcons.trash_fill,
      'person.circle': CupertinoIcons.person_circle,
      'person.circle.fill': CupertinoIcons.person_circle_fill,
    };
    return iconMap[sfSymbol] ?? CupertinoIcons.circle;
  }

  /// Shows a standard adaptive alert dialog
  ///
  /// The [icon] parameter accepts:
  /// - iOS 26+: String (SF Symbol name, e.g., "checkmark.circle.fill")
  /// - iOS <26: IconData (e.g., CupertinoIcons.checkmark_alt_circle_fill)
  /// - Android: IconData (e.g., Icons.check_circle)
  /// - ImageProvider, such as AssetImage, FileImage, or NetworkImage
  /// - Widget, such as ImageIcon
  ///
  /// [iconAsset] is a convenience wrapper for passing an asset image path,
  /// matching the AdaptiveNavigationDestination asset-image API.
  ///
  /// Returns a Future that resolves to void when the dialog is dismissed
  static Future<void> show({
    required BuildContext context,
    required String title,
    String? message,
    required List<AlertAction> actions,
    dynamic icon,
    String? iconAsset,
    String? assetPackage,
    double? iconSize,
    Color? iconColor,
    String? oneTimeCode,
  }) {
    final iconSource = _resolveIconSource(
      icon: icon,
      iconAsset: iconAsset,
      assetPackage: assetPackage,
    );

    // iOS 26+ - Use native iOS 26 alert dialog
    if (PlatformInfo.isIOS26OrHigher()) {
      return showCupertinoDialog<void>(
        context: context,
        barrierColor: CupertinoColors.transparent,
        builder: (context) => IOS26AlertDialog(
          title: title,
          message: message,
          actions: actions,
          icon: iconSource.symbolName,
          iconAsset: iconSource.assetPath,
          iconAssetPackage: iconSource.assetPackage,
          iconFilePath: iconSource.filePath,
          iconNetworkUrl: iconSource.networkUrl,
          iconSize: iconSize,
          iconColor: iconColor,
          oneTimeCode: oneTimeCode,
          input: null, // No input for standard dialog
        ),
      );
    }

    // iOS 18 and below - Use CupertinoAlertDialog
    if (PlatformInfo.isIOS) {
      return showCupertinoDialog<void>(
        context: context,
        builder: (context) {
          Widget? contentWidget;
          final hasLegacyIcon = iconSource.hasVisual;
          final hasOtpCode = oneTimeCode != null;
          final hasContentBelowMessage = hasOtpCode;
          final hasScrollableLegacyContent =
              hasLegacyIcon || hasOtpCode || message != null;

          // Build custom content if icon or OTP is present
          if (hasScrollableLegacyContent) {
            contentWidget = ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: hasContentBelowMessage ? 60 : 0,
                maxHeight: 300,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasLegacyIcon) ...[
                      Center(
                        child: _buildAlertIconWidget(
                          iconSource,
                          size: iconSize,
                          color: iconColor ?? CupertinoColors.systemBlue,
                          platform: TargetPlatform.iOS,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (message != null) ...[
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (hasContentBelowMessage) const SizedBox(height: 12),
                    ],
                    if (hasOtpCode) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          oneTimeCode,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Courier',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            );
          }

          return CupertinoAlertDialog(
            title: Text(title),
            content: contentWidget != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: contentWidget,
                  )
                : null,
            actions: actions.map((action) {
              return CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  action.onPressed();
                },
                isDefaultAction: action.style == AlertActionStyle.primary,
                isDestructiveAction:
                    action.style == AlertActionStyle.destructive,
                child: Text(action.title),
              );
            }).toList(),
          );
        },
      );
    }

    // Android - Use Material Design AlertDialog
    return _showMaterialDialog(
      context: context,
      title: title,
      message: message,
      actions: actions,
      icon: icon,
      iconAsset: iconAsset,
      assetPackage: assetPackage,
      iconSize: iconSize,
      iconColor: iconColor,
      oneTimeCode: oneTimeCode,
      input: null,
    );
  }

  /// Shows an adaptive alert dialog with text input
  ///
  /// The [input] parameter configures the text input field.
  /// Returns a Future containing the entered text or null if cancelled
  static Future<String?> inputShow({
    required BuildContext context,
    required String title,
    String? message,
    required List<AlertAction> actions,
    required AdaptiveAlertDialogInput input,
    dynamic icon,
    String? iconAsset,
    String? assetPackage,
    double? iconSize,
    Color? iconColor,
  }) {
    final iconSource = _resolveIconSource(
      icon: icon,
      iconAsset: iconAsset,
      assetPackage: assetPackage,
    );

    // iOS 26+ - Use native iOS 26 alert dialog with input
    if (PlatformInfo.isIOS26OrHigher()) {
      return showCupertinoDialog<String?>(
        context: context,
        builder: (context) => IOS26AlertDialog(
          title: title,
          message: message,
          actions: actions,
          icon: iconSource.symbolName,
          iconAsset: iconSource.assetPath,
          iconAssetPackage: iconSource.assetPackage,
          iconFilePath: iconSource.filePath,
          iconNetworkUrl: iconSource.networkUrl,
          iconSize: iconSize,
          iconColor: iconColor,
          oneTimeCode: null,
          input: input,
        ),
      );
    }

    // iOS 18 and below - Use CupertinoAlertDialog with text field
    if (PlatformInfo.isIOS) {
      final textController = TextEditingController(text: input.initialValue);

      return showCupertinoDialog<String?>(
        context: context,
        builder: (context) {
          Widget? contentWidget;

          // Build custom content with text field
          contentWidget = ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 100, maxHeight: 300),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (iconSource.hasVisual) ...[
                    Center(
                      child: _buildAlertIconWidget(
                        iconSource,
                        size: iconSize,
                        color: iconColor ?? CupertinoColors.systemBlue,
                        platform: TargetPlatform.iOS,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (message != null) ...[
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                  ],
                  CupertinoTextField(
                    controller: textController,
                    placeholder: input.placeholder,
                    keyboardType: input.keyboardType,
                    obscureText: input.obscureText,
                    maxLength: input.maxLength,
                    autofocus: true,
                    padding: const EdgeInsets.all(12),
                  ),
                ],
              ),
            ),
          );

          return CupertinoAlertDialog(
            title: Text(title),
            content: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: contentWidget,
            ),
            actions: actions.map((action) {
              return CupertinoDialogAction(
                onPressed: () {
                  if (action.style == AlertActionStyle.cancel) {
                    // Cancel button returns null
                    Navigator.of(context).pop<String?>(null);
                  } else {
                    // Other buttons return the entered text
                    final text = textController.text.trim();
                    Navigator.of(
                      context,
                    ).pop<String?>(text.isNotEmpty ? text : null);
                  }
                  action.onPressed();
                },
                isDefaultAction: action.style == AlertActionStyle.primary,
                isDestructiveAction:
                    action.style == AlertActionStyle.destructive,
                child: Text(action.title),
              );
            }).toList(),
          );
        },
      );
    }

    // Android - Use Material Design AlertDialog with TextField
    return _showMaterialDialog<String?>(
      context: context,
      title: title,
      message: message,
      actions: actions,
      icon: icon,
      iconAsset: iconAsset,
      assetPackage: assetPackage,
      iconSize: iconSize,
      iconColor: iconColor,
      oneTimeCode: null,
      input: input,
    );
  }

  /// Internal helper method for showing Material dialogs
  static Future<T?> _showMaterialDialog<T>({
    required BuildContext context,
    required String title,
    String? message,
    required List<AlertAction> actions,
    dynamic icon,
    String? iconAsset,
    String? assetPackage,
    double? iconSize,
    Color? iconColor,
    String? oneTimeCode,
    AdaptiveAlertDialogInput? input,
  }) {
    final textController = TextEditingController(text: input?.initialValue);
    final iconSource = _resolveIconSource(
      icon: icon,
      iconAsset: iconAsset,
      assetPackage: assetPackage,
    );

    return showDialog<T>(
      context: context,
      builder: (context) {
        // Build custom content if icon, OTP, or textfield is present
        Widget? contentWidget;
        final hasMaterialIcon = iconSource.hasVisual;
        final hasOtpCode = oneTimeCode != null;
        final hasInput = input != null;
        final hasContentBelowMessage = hasOtpCode || hasInput;
        if (hasMaterialIcon ||
            oneTimeCode != null ||
            message != null ||
            input != null) {
          contentWidget = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasMaterialIcon) ...[
                _buildAlertIconWidget(
                  iconSource,
                  size: iconSize,
                  color: iconColor ?? Colors.blue,
                  platform: TargetPlatform.android,
                ),
                const SizedBox(height: 12),
              ],
              if (message != null) ...[
                Text(message, textAlign: TextAlign.center),
                if (hasContentBelowMessage) const SizedBox(height: 16),
              ],
              if (hasOtpCode) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    oneTimeCode,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (input != null) ...[
                TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: input.placeholder,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: input.keyboardType,
                  obscureText: input.obscureText,
                  maxLength: input.maxLength,
                  autofocus: true,
                ),
              ],
            ],
          );
        }

        // Separate actions by type
        final normalActions = actions
            .where((a) => a.style != AlertActionStyle.cancel)
            .toList();
        final cancelAction = actions.firstWhere(
          (a) => a.style == AlertActionStyle.cancel,
          orElse: () => AlertAction(
            title: MaterialLocalizations.of(context).cancelButtonLabel,
            onPressed: () {},
            style: AlertActionStyle.cancel,
          ),
        );

        return AlertDialog(
          title: Text(title),
          content: contentWidget,
          actions: [
            ...normalActions.map((action) {
              Color? buttonColor;
              switch (action.style) {
                case AlertActionStyle.destructive:
                  buttonColor = Colors.red;
                  break;
                case AlertActionStyle.primary:
                  buttonColor = Theme.of(context).colorScheme.primary;
                  break;
                case AlertActionStyle.success:
                  buttonColor = Colors.green;
                  break;
                case AlertActionStyle.warning:
                  buttonColor = Colors.orange;
                  break;
                case AlertActionStyle.info:
                  buttonColor = Colors.blue;
                  break;
                default:
                  buttonColor = null;
              }

              return TextButton(
                onPressed: action.enabled
                    ? () {
                        if (input != null) {
                          // Input dialog - return the text
                          final text = textController.text.trim();
                          Navigator.of(
                            context,
                          ).pop<String?>(text.isNotEmpty ? text : null);
                        } else {
                          // Normal dialog - just close
                          Navigator.of(context).pop();
                        }
                        action.onPressed();
                      }
                    : null,
                style: buttonColor != null
                    ? TextButton.styleFrom(foregroundColor: buttonColor)
                    : null,
                child: Text(action.title),
              );
            }),
            if (actions.any((a) => a.style == AlertActionStyle.cancel))
              TextButton(
                onPressed: () {
                  // Cancel button always returns null for input dialogs
                  if (input != null) {
                    Navigator.of(context).pop<String?>(null);
                  } else {
                    Navigator.of(context).pop();
                  }
                  cancelAction.onPressed();
                },
                child: Text(cancelAction.title),
              ),
          ],
        );
      },
    );
  }
}
