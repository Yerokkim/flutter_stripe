import 'dart:js_interop';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:stripe_js/stripe_api.dart' as js;
import 'package:stripe_js/stripe_js.dart' as js;
import 'package:web/web.dart' as web;

import '../../flutter_stripe_web.dart';

export 'package:stripe_js/src/api/elements/payment_element_options.dart';
export 'package:stripe_js/stripe_api.dart'
    show
        ElementAppearance,
        ElementTheme,
        ElementAppearanceLabels,
        PaymentElementLayout,
        PaymentElementDefaultValues,
        PaymentElementBillingDetails,
        PaymentElementBillingDetailsAddress,
        PaymentElementWalletOptions,
        PaymentElementFieldRequired;

typedef PaymentElementTheme = js.ElementTheme;

class PaymentElement extends StatefulWidget {
  final String? clientSecret;
  final String? customerSessionClientSecret;

  final int? amount;
  final String? currency;
  final String? mode;
  final String? paymentMethodCreation;
  final List<String>? paymentMethodTypes;

  final double? width;
  final double? height;
  final CardStyle? style;
  final CardPlaceholder? placeholder;
  final bool enablePostalCode;
  final bool autofocus;
  final FocusNode? focusNode;
  final CardFocusCallback? onFocus;
  final CardChangedCallback onCardChanged;
  final PaymentElementLayout layout;
  final js.ElementAppearance? appearance;
  final js.PaymentElementDefaultValues? defaultValues;
  final js.PaymentElementBusiness? business;
  final dynamic paymentMethodOrder;
  final js.PaymentElementFields? fields;
  final bool? readOnly;
  final js.PaymentElementOptionsTerms? terms;
  final js.PaymentElementWalletOptions? wallets;
  final js.PaymentElementApplePayOptions? applePay;
  final String? locale;

  const PaymentElement({
    super.key,
    this.clientSecret,
    this.customerSessionClientSecret,
    this.amount,
    this.currency,
    this.mode,
    this.paymentMethodTypes,
    this.paymentMethodCreation,
    this.width,
    this.height,
    this.style,
    this.placeholder,
    this.enablePostalCode = false,
    this.autofocus = false,
    this.focusNode,
    this.onFocus,
    required this.onCardChanged,
    this.layout = PaymentElementLayout.accordion,
    this.appearance,
    this.locale,
    this.defaultValues,
    this.business,
    this.paymentMethodOrder,
    this.fields,
    this.readOnly,
    this.terms,
    this.wallets,
    this.applePay,
  });

  @override
  State<PaymentElement> createState() => PaymentElementState();
}

class PaymentElementState extends State<PaymentElement> {
  static bool _alreadyRegistered = false;

  web.HTMLDivElement _divElement = web.HTMLDivElement();
  double height = 2.0;
  bool _stripeMounted = false;

  js.PaymentElement? get element => WebStripe.element as js.PaymentElement?;
  set element(js.StripeElement? value) => WebStripe.element = value;

  js.StripeElements? get elements => WebStripe.elements;
  set elements(js.StripeElements? value) => WebStripe.elements = value;

  final FocusNode _focusNode = FocusNode(debugLabel: 'CardField');
  FocusNode get _effectiveNode => widget.focusNode ?? _focusNode;

  late final resizeObserver = web.ResizeObserver(
    ((JSArray<web.ResizeObserverEntry> entries, web.ResizeObserver observer) {
      if (widget.height == null) {
        for (final entry in entries.toDart) {
          final cr = entry.contentRect;
          setState(() {
            height = cr.height.toDouble();
            _divElement.style.height = '${height}px';
          });
        }
      }
    }).toJS,
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerAndMountStripeIframe();
    });
  }

  void _registerAndMountStripeIframe() {
    if (_alreadyRegistered) return;

    _divElement = web.HTMLDivElement()
      ..id = 'payment-element'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '${widget.height ?? height}'
      ..style.overflow = 'scroll'
      ..style.overflowX = 'hidden';

    ui.platformViewRegistry.registerViewFactory(
      'stripe_payment_element',
      (int viewId) => _divElement,
    );
    _alreadyRegistered = true;

    elements = WebStripe.js.elements(createOptions());
    element = elements!.createPayment(elementOptions())
      ..mount('#payment-element'.toJS)
      ..onBlur(requestBlur)
      ..onFocus(requestFocus)
      ..onChange(onCardChanged);

    setState(() {
      _stripeMounted = true;
    });
  }

  void requestBlur(response) {
    _effectiveNode.unfocus();
  }

  void requestFocus(response) {
    _effectiveNode.requestFocus();
  }

  void onCardChanged(js.PaymentElementChangeEvent response) {
    final details = CardFieldInputDetails(
      complete: response.complete,
    );
    widget.onCardChanged(details);
  }

  @override
  void dispose() {
    resizeObserver.disconnect();
    element?.unmount();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      focusNode: _effectiveNode,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: double.infinity,
          maxHeight: height,
        ),
        child: _stripeMounted
            ? const HtmlElementView(viewType: 'stripe_payment_element')
            : const SizedBox.shrink(),
      ),
    );
  }

  js.JsElementsCreateOptions createOptions() {
    final appearance = widget.appearance ??
        js.ElementAppearance.fromJson({
          'variables': {
            'colorPrimary': '#000000',
            'fontFamily': 'inherit',
          },
          'rules': {
            '.Input': {
              'autocomplete': 'off',
              'inputmode': 'text',
              'padding': '12px',
              'fontSize': '16px',
            },
          },
        });

    if (widget.clientSecret?.isNotEmpty == true) {
      return js.JsElementsCreateOptions(
        clientSecret: widget.clientSecret,
        customerSessionClientSecret: widget.customerSessionClientSecret,
        appearance: appearance.toJson().jsify() as js.JsElementAppearance,
        locale: widget.locale,
      );
    }

    return js.JsElementsCreateOptions(
      amount: widget.amount,
      currency: widget.currency,
      mode: widget.mode,
      paymentMethodTypes: widget.paymentMethodTypes
          ?.map((pmt) => pmt.toJS)
          .toList(growable: false)
          .toJS,
      paymentMethodCreation: widget.paymentMethodCreation,
      appearance: appearance.toJson().jsify() as js.JsElementAppearance,
      locale: widget.locale,
    );
  }

  js.PaymentElementOptions elementOptions() {
    return js.PaymentElementOptions(
      layout: widget.layout,
      defaultValues: widget.defaultValues,
      business: widget.business,
      paymentMethodOrder: widget.paymentMethodOrder,
      fields: widget.fields,
      readOnly: widget.readOnly,
      terms: widget.terms,
      wallets: widget.wallets,
      applePay: widget.applePay,
    );
  }
}
