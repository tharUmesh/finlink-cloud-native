import 'package:finlink_mobile/features/base_screen.dart';
import 'package:finlink_mobile/features/home/qr_scanner/qr_scanner_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QrScannerScreen extends BaseScreen {
	const QrScannerScreen({super.key});

	@override
	Widget mainContent(BuildContext context) {
		return ChangeNotifierProvider(
			create: (_) => QrScannerViewmodel(),
			child: Consumer<QrScannerViewmodel>(
				builder: (context, viewmodel, child) {
					return SafeArea(
						child: Padding(
							padding: const EdgeInsets.all(16),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: [
									Row(
										children: [
											IconButton(
												onPressed: () => Navigator.pop(context),
												icon: const Icon(Icons.arrow_back_ios_new_rounded),
											),
											const SizedBox(width: 8),
											const Text(
												'QR Scanner',
												style: TextStyle(
													fontSize: 22,
													fontWeight: FontWeight.w700,
												),
											),
										],
									),
									const SizedBox(height: 12),
									Expanded(
										child: ClipRRect(
											borderRadius: BorderRadius.circular(20),
											child: QRView(
												key: viewmodel.qrKey,
												onQRViewCreated: viewmodel.onQRViewCreated,
												overlay: QrScannerOverlayShape(
													borderColor: const Color(0xFF6A4CE1),
													borderRadius: 14,
													borderLength: 28,
													borderWidth: 8,
													cutOutSize: 260,
												),
											),
										),
									),
									const SizedBox(height: 14),
									Row(
										mainAxisAlignment: MainAxisAlignment.center,
										children: [
											FilledButton.icon(
												onPressed: viewmodel.toggleFlash,
												icon: Icon(
													viewmodel.isFlashOn
															? Icons.flash_on_rounded
															: Icons.flash_off_rounded,
												),
												label: const Text('Flash'),
											),
											const SizedBox(width: 12),
											FilledButton.icon(
												onPressed: viewmodel.flipCamera,
												icon: const Icon(Icons.flip_camera_android_rounded),
												label: const Text('Flip'),
											),
										],
									),
									const SizedBox(height: 14),
									Container(
										padding: const EdgeInsets.all(12),
										decoration: BoxDecoration(
											borderRadius: BorderRadius.circular(12),
											color: const Color(0xFFF3F4F8),
										),
										child: Text(
											'Scanned: ${viewmodel.scannedValue}',
											maxLines: 2,
											overflow: TextOverflow.ellipsis,
											style: const TextStyle(
												fontSize: 14,
												fontWeight: FontWeight.w500,
											),
										),
									),
								],
							),
						),
					);
				},
			),
		);
	}
}
