import 'package:flutter/material.dart';

class SuccessDialog extends StatelessWidget {
	final String title;
	final String message;
	final String buttonText;
	final VoidCallback onPressed;

	const SuccessDialog({
		super.key,
		required this.title,
		required this.message,
		required this.buttonText,
		required this.onPressed,
	});

	@override
	Widget build(BuildContext context) {
		return AlertDialog(
			icon: const Icon(
				Icons.check_circle_rounded,
				size: 52,
				color: Colors.green,
			),
			title: Text(title),
			content: Text(message),
			actions: [
				SizedBox(
					width: double.infinity,
					child: ElevatedButton(
						onPressed: onPressed,
						child: Text(buttonText),
					),
				),
			],
		);
	}
}
