import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/auth/view_models/login_view_model.dart';
import 'package:apoio_app/ui/core/widgets/inline_error.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  final ManagementRepository api;
  const LoginView({super.key, required this.api});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  bool _showPassword = false;
  late final LoginViewModel _viewModel;
  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel(widget.api)..addListener(_refresh);
  }

  void _refresh() => setState(() {});
  @override
  void dispose() {
    _viewModel.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_viewModel.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _viewModel.login(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
              key: _form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Acesso da instituição',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text(
                        'Use a conta vinculada à sua instituição para administrar o estoque.'),
                    if (widget.api.signInNotice != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(widget.api.signInNotice!,
                              semanticsLabel: widget.api.signInNotice)),
                    const SizedBox(height: 24),
                    TextFormField(
                        key: const ValueKey('login-email'),
                        controller: _email,
                        enabled: !_viewModel.busy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username],
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        validator: (v) => v == null ||
                                !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(v.trim())
                            ? 'Informe um e-mail válido.'
                            : null),
                    const SizedBox(height: 16),
                    TextFormField(
                        key: const ValueKey('login-password'),
                        controller: _password,
                        enabled: !_viewModel.busy,
                        obscureText: !_showPassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                            labelText: 'Senha',
                            suffixIcon: IconButton(
                                onPressed: () => setState(
                                    () => _showPassword = !_showPassword),
                                tooltip: _showPassword
                                    ? 'Ocultar senha'
                                    : 'Mostrar senha',
                                icon: Icon(_showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility))),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Informe sua senha.'
                            : null),
                    if (_viewModel.error != null)
                      InlineError(_viewModel.error!),
                    const SizedBox(height: 24),
                    FilledButton(
                        onPressed: _viewModel.busy ? null : _login,
                        child: Text(_viewModel.busy ? 'Entrando…' : 'Entrar')),
                    const SizedBox(height: 16),
                    const Text(
                        'A consulta pública não exige login. O acesso à gestão depende de um vínculo autorizado.'),
                  ]))));
}
