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
  late final web.HTMLDivElement _divElement;
  late final double height;
  late final web.MutationObserver mutationObserver;

  @override
  void initState() {
    super.initState();

    // Prevent resizing when keyboard opens
    final body = web.document.body!;
    body.style.position = 'fixed';
    body.style.width = '100vw';
    body.style.height = '100vh';
    body.style.overflow = 'hidden';

    height = widget.height ?? 400;

    _divElement = web.HTMLDivElement()
      ..id = 'payment-element'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '${height}px'
      ..style.overflow = 'hidden';

    ui.platformViewRegistry.registerViewFactory(
      'stripe_payment_element',
      (int viewId) => _divElement,
    );

    mutationObserver = web.MutationObserver(((entries, observer) {
      final el = web.document.getElementById('payment-element');
      if (el != null) {
        observer.disconnect();
        final stripeElements = WebStripe.js.elements(createOptions());
        WebStripe.elements = stripeElements;
        WebStripe.element = stripeElements.createPayment(elementOptions())
          ..mount('#payment-element'.toJS)
          ..onBlur(requestBlur)
          ..onFocus(requestFocus)
          ..onChange(onCardChanged);
      }
    }).toJS);

    mutationObserver.observe(
      web.document,
      web.MutationObserverInit(childList: true, subtree: true),
    );
  }

  js.PaymentElement? get element => WebStripe.element as js.PaymentElement?;
  set element(js.StripeElement? value) => WebStripe.element = value;
  js.StripeElements? get elements => WebStripe.elements;
  set elements(js.StripeElements? value) => WebStripe.elements = value;

  void requestBlur(response) => _effectiveNode.unfocus();
  void requestFocus(response) => _effectiveNode.requestFocus();

  void onCardChanged(js.PaymentElementChangeEvent response) {
    final details = CardFieldInputDetails(complete: response.complete);
    widget.onCardChanged(details);
  }

  final FocusNode _focusNode = FocusNode(debugLabel: 'CardField');
  FocusNode get _effectiveNode => widget.focusNode ?? _focusNode;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: const HtmlElementView(viewType: 'stripe_payment_element'),
      ),
    );
  }

  js.JsElementsCreateOptions createOptions() {
    final appearance = widget.appearance ?? js.ElementAppearance();
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
      paymentMethodTypes:
          widget.paymentMethodTypes?.map((e) => e.toJS).toList().toJS,
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

  @override
  void dispose() {
    mutationObserver.disconnect();
    element?.unmount();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PaymentElement oldWidget) {
    super.didUpdateWidget(oldWidget);
  }
}
