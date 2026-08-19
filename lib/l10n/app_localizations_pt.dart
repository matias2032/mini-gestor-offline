// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get signIn => 'Entrar';

  @override
  String helloUser(String name) {
    return 'Olá, $name';
  }

  @override
  String get welcomeBack => 'Bem-vindo de volta';

  @override
  String get enterPasswordToContinue =>
      'Digite a sua palavra-passe para continuar.';

  @override
  String get password => 'Palavra-passe';

  @override
  String get passwordRequired => 'A palavra-passe é obrigatória';

  @override
  String get createAccount => 'Criar conta';

  @override
  String get welcome => 'Bem-vindo';

  @override
  String get fillDetailsToStart =>
      'Preencha os seus dados para começar a usar a aplicação.';

  @override
  String get nameLabel => 'Nome *';

  @override
  String get nameRequired => 'O nome é obrigatório';

  @override
  String get lastName => 'Apelido';

  @override
  String get phone => 'Telefone';

  @override
  String get email => 'Email';

  @override
  String get invalidEmail => 'Email inválido';

  @override
  String get businessName => 'Nome do negócio';

  @override
  String get currencyLabel => 'Moeda *';

  @override
  String get passwordLabel => 'Palavra-passe *';

  @override
  String get passwordMinLength =>
      'A palavra-passe deve ter pelo menos 6 caracteres';

  @override
  String get confirmPasswordLabel => 'Confirmar palavra-passe *';

  @override
  String get passwordsDoNotMatch => 'As palavras-passe não coincidem';

  @override
  String get failedToCreateAccount => 'Falha ao criar a conta.';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get updateDetailsBelow => 'Atualize os dados da sua conta abaixo.';

  @override
  String get nameFieldLabel => 'Nome';

  @override
  String get nameRequiredDot => 'O nome é obrigatório.';

  @override
  String get currencyFieldLabel => 'Moeda';

  @override
  String get couldNotUpdateProfile => 'Não foi possível atualizar o perfil.';

  @override
  String get profileUpdatedRelogin =>
      'Perfil atualizado. Inicie sessão novamente.';

  @override
  String get profileUpdated => 'Perfil atualizado.';

  @override
  String get saveChanges => 'Guardar alterações';

  @override
  String get changePasswordTitle => 'Alterar palavra-passe';

  @override
  String get confirmCurrentPasswordPrompt =>
      'Confirme a sua palavra-passe atual para definir uma nova.';

  @override
  String get currentPasswordLabel => 'Palavra-passe atual';

  @override
  String get currentPasswordRequired => 'A palavra-passe atual é obrigatória.';

  @override
  String get newPasswordLabel => 'Nova palavra-passe';

  @override
  String get newPasswordRequired => 'A nova palavra-passe é obrigatória.';

  @override
  String get newPasswordMinLength =>
      'A palavra-passe deve ter pelo menos 6 caracteres.';

  @override
  String get confirmNewPasswordLabel => 'Confirmar nova palavra-passe';

  @override
  String get passwordsDoNotMatchDot => 'As palavras-passe não coincidem.';

  @override
  String get couldNotChangePassword =>
      'Não foi possível alterar a palavra-passe.';

  @override
  String get passwordChangedRelogin =>
      'Palavra-passe alterada. Inicie sessão novamente.';

  @override
  String get passwordChanged => 'Palavra-passe alterada.';

  @override
  String get changePasswordButton => 'Alterar palavra-passe';

  @override
  String get deleteCustomer => 'Eliminar cliente';

  @override
  String confirmDeleteCustomerMessage(String name) {
    return 'Tem a certeza de que deseja eliminar \"$name\"? O histórico de vendas associado será mantido.';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get customersTitle => 'Clientes';

  @override
  String get newCustomer => 'Novo cliente';

  @override
  String get noCustomersYet => 'Ainda não há clientes registados.';

  @override
  String get editCustomer => 'Editar cliente';

  @override
  String get notesLabel => 'Notas';

  @override
  String get createCustomer => 'Criar cliente';

  @override
  String get dashboardTitle => 'Painel';

  @override
  String get hello => 'Olá';

  @override
  String get salesDoingIntro => 'Aqui está o desempenho das suas vendas.';

  @override
  String get finalizedSales => 'Vendas finalizadas';

  @override
  String get totalRevenue => 'Receita total';

  @override
  String get settledCreditSales => 'Vendas a crédito liquidadas';

  @override
  String get dashboardComingSoonTitle => 'Painel a caminho';

  @override
  String get dashboardComingSoonMessage =>
      'Estamos a reconstruir o painel da sua loja para a nova estrutura multi-loja. Volte a verificar em breve.';

  @override
  String get settledCreditRevenueLabel => 'Receita de crédito liquidada';

  @override
  String get dashboardNoStoreSelected =>
      'Selecione uma loja para ver as suas estatísticas.';

  @override
  String saleCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vendas',
      one: '1 venda',
      zero: '0 vendas',
    );
    return '$_temp0';
  }

  @override
  String get suppliersTitle => 'Fornecedores';

  @override
  String get noSuppliersYet => 'Ainda não há fornecedores registados.';

  @override
  String get newSupplier => 'Novo fornecedor';

  @override
  String get editSupplier => 'Editar fornecedor';

  @override
  String get deleteSupplier => 'Eliminar fornecedor';

  @override
  String get createSupplier => 'Criar fornecedor';

  @override
  String get addressLabel => 'Morada';

  @override
  String get deleteSupplierConfirmationGeneric =>
      'Tem a certeza de que deseja eliminar este fornecedor?';

  @override
  String confirmDeleteSupplierMessage(String name) {
    return 'Tem a certeza de que deseja eliminar \"$name\"?';
  }

  @override
  String get descriptionOptionalLabel => 'Descrição (opcional)';

  @override
  String get filterExpensesTitle => 'Filtrar despesas';

  @override
  String get allLabel => 'Todas';

  @override
  String get supplierLabel => 'Fornecedor';

  @override
  String get startDateLabel => 'Data inicial';

  @override
  String get endDateLabel => 'Data final';

  @override
  String get clearLabel => 'Limpar';

  @override
  String get applyLabel => 'Aplicar';

  @override
  String get newExpense => 'Nova despesa';

  @override
  String get editExpense => 'Editar despesa';

  @override
  String get descriptionLabel => 'Descrição';

  @override
  String get descriptionRequired => 'A descrição é obrigatória';

  @override
  String get amountLabel => 'Valor (MZN)';

  @override
  String get amountRequired => 'O valor é obrigatório';

  @override
  String get invalidAmount => 'Valor inválido';

  @override
  String get supplierOptionalLabel => 'Fornecedor (opcional)';

  @override
  String get noneLabel => 'Nenhum';

  @override
  String dateLabel(String date) {
    return 'Data: $date';
  }

  @override
  String get createExpense => 'Criar despesa';

  @override
  String get saveLabel => 'Guardar';

  @override
  String get expensesTitle => 'Despesas';

  @override
  String get deleteExpense => 'Eliminar despesa';

  @override
  String confirmDeleteExpenseMessage(String name) {
    return 'Tem a certeza de que deseja eliminar \"$name\"?';
  }

  @override
  String get deletionReasonLabel => 'Motivo da eliminação';

  @override
  String get noExpensesYet => 'Nenhuma despesa registada.';

  @override
  String get unknownCustomer => 'Cliente desconhecido';

  @override
  String customerNumber(String id) {
    return 'Cliente #$id';
  }

  @override
  String get enterValidPaymentAmount => 'Indique um valor de pagamento válido.';

  @override
  String get paymentExceedsRemainingDebt =>
      'O pagamento excede a dívida restante.';

  @override
  String get paymentRegistered => 'Pagamento registado.';

  @override
  String get couldNotRegisterPayment =>
      'Não foi possível registar o pagamento.';

  @override
  String get cancelSale => 'Cancelar venda';

  @override
  String get cancellationReasonLabel => 'Motivo do cancelamento';

  @override
  String get back => 'Voltar';

  @override
  String get cancelSaleButton => 'Cancelar Venda';

  @override
  String get couldNotCancelSale => 'Não foi possível cancelar a venda.';

  @override
  String get creditSaleTitle => 'Venda a Crédito';

  @override
  String get saleNotFound => 'Venda não encontrada.';

  @override
  String get totalLabel => 'Total';

  @override
  String get paidSoFarLabel => 'Pago até agora';

  @override
  String get remainingDebtLabel => 'Dívida restante';

  @override
  String get statusLabel => 'Estado';

  @override
  String get paymentStatusLabel => 'Estado do pagamento';

  @override
  String get dueDateLabel => 'Data de vencimento';

  @override
  String get registerPayment => 'Registar pagamento';

  @override
  String get amountFieldLabel => 'Valor';

  @override
  String get enterValidAmount => 'Indique um valor válido';

  @override
  String get paymentMethodLabel => 'Método de pagamento';

  @override
  String get cashMethod => 'Dinheiro';

  @override
  String get bankTransferMethod => 'Transferência bancária';

  @override
  String get mpesaMethod => 'M-Pesa';

  @override
  String get emolaMethod => 'E-Mola';

  @override
  String get otherMethod => 'Outro';

  @override
  String get notesOptionalLabel => 'Notas (opcional)';

  @override
  String get paymentHistory => 'Histórico de pagamentos';

  @override
  String get noPaymentsYet => 'Ainda não há pagamentos registados.';

  @override
  String get creditSalesTitle => 'Vendas a Crédito';

  @override
  String get noOutstandingCreditSales => 'Não há vendas a crédito em aberto.';

  @override
  String creditSaleSubtitle(
    String reference,
    String description,
    String owed,
    String currency,
    String paid,
  ) {
    return '$reference — $description\nEm dívida: $owed $currency • Pago até agora: $paid $currency';
  }

  @override
  String get salesGroupLabel => 'Vendas';

  @override
  String get finishedSalesLabel => 'Vendas Concluídas';

  @override
  String get categoriesLabel => 'Categorias';

  @override
  String get financialStatementsLabel => 'Extratos Financeiros';

  @override
  String get logOut => 'Terminar sessão';

  @override
  String get changeThemeLabel => 'Alterar tema';

  @override
  String get confirmLogoutTitle => 'Confirmar saída';

  @override
  String get confirmLogoutMessage =>
      'Tem a certeza de que deseja terminar sessão?';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get statementDetailTitle => 'Detalhe do Extrato';

  @override
  String salesCountLabel(int count) {
    return 'Vendas ($count)';
  }

  @override
  String expensesCountLabel(int count) {
    return 'Despesas ($count)';
  }

  @override
  String get balanceLabel => 'Saldo';

  @override
  String get salesSectionTitle => 'Vendas';

  @override
  String get noSalesInPeriod => 'Sem vendas neste período.';

  @override
  String get expensesSectionTitle => 'Despesas';

  @override
  String get noExpensesInPeriod => 'Sem despesas neste período.';

  @override
  String get generateStatementTitle => 'Gerar Extrato';

  @override
  String get periodLabel => 'Período';

  @override
  String get selectBothDatesMessage =>
      'Selecione a data de início e a data de fim.';

  @override
  String get endDateBeforeStartDateMessage =>
      'A data de fim não pode ser anterior à data de início.';

  @override
  String get selectStartDate => 'Selecionar data de início';

  @override
  String get selectEndDate => 'Selecionar data de fim';

  @override
  String startDatePrefix(String date) {
    return 'Início: $date';
  }

  @override
  String endDatePrefix(String date) {
    return 'Fim: $date';
  }

  @override
  String get generateButtonLabel => 'Gerar';

  @override
  String get financialStatementsTitle => 'Extratos Financeiros';

  @override
  String get noStatementsYet => 'Ainda não foram gerados extratos.';

  @override
  String get deleteStatementTitle => 'Eliminar extrato';

  @override
  String confirmDeleteStatementMessage(String name) {
    return 'Eliminar o extrato $name? Esta ação não pode ser desfeita.';
  }

  @override
  String get couldNotDeleteStatement => 'Não foi possível eliminar o extrato.';

  @override
  String get generateStatementTooltip => 'Gerar extrato';

  @override
  String generatedOnPrefix(String date) {
    return 'Gerado $date';
  }

  @override
  String get nameRequiredMessage => 'O nome é obrigatório';

  @override
  String get createCategoryButton => 'Criar';

  @override
  String get newSaleTitle => 'Nova Venda';

  @override
  String get selectCustomerMessage => 'Selecione um cliente.';

  @override
  String get enterWalkInNameMessage => 'Indique o nome do cliente ocasional.';

  @override
  String get enterValidInitialPaymentMessage =>
      'Indique um valor de entrada válido.';

  @override
  String get initialPaymentExceedsTotalMessage =>
      'A entrada não pode exceder o total da venda.';

  @override
  String get descriptionRequiredMessage => 'A descrição é obrigatória';

  @override
  String get totalAmountLabel => 'Valor total';

  @override
  String get enterValidAmountMessage => 'Indique um valor válido';

  @override
  String get normalLabel => 'Normal';

  @override
  String get creditLabel => 'Crédito';

  @override
  String get useExistingCustomerLabel => 'Usar cliente existente';

  @override
  String get associateExistingCustomerOptionalLabel =>
      'Associar um cliente existente (opcional)';

  @override
  String get customerLabel => 'Cliente';

  @override
  String get walkInCustomerNameLabel => 'Nome do cliente ocasional';

  @override
  String get addDueDateOptionalLabel =>
      'Adicionar data de vencimento (opcional)';

  @override
  String dueDatePrefix(String date) {
    return 'Vence: $date';
  }

  @override
  String get initialPaymentOptionalLabel => 'Entrada (opcional)';

  @override
  String get initialPaymentHelperText =>
      'Deixe em branco se ainda não foi pago nada — o valor total fica em dívida.';

  @override
  String get createSaleButton => 'Criar Venda';

  @override
  String get finishedSalesTitle => 'Vendas Concluídas';

  @override
  String get creditSalesTooltip => 'Vendas a crédito';

  @override
  String get typeLabel => 'Tipo';

  @override
  String get noFinishedSalesYet => 'Ainda não há vendas concluídas.';

  @override
  String get newSaleTooltip => 'Nova venda';

  @override
  String get cancelSaleTitle => 'Cancelar venda';

  @override
  String get backLabel => 'Voltar';

  @override
  String get noCustomerLabel => 'Sem cliente';

  @override
  String customerNumberLabel(int id) {
    return 'Cliente #$id';
  }

  @override
  String get immediateLabel => 'Imediata';

  @override
  String get noInstallmentsRegistered => 'Nenhuma prestação registada.';

  @override
  String paidInInstallmentsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'prestações',
      one: 'prestação',
      zero: 'prestações',
    );
    return 'Pago em $count $_temp0:';
  }

  @override
  String get splashLoading => 'A preparar a aplicação...';

  @override
  String get switchStoreTooltip => 'Mudar de loja';

  @override
  String get storesTitle => 'Lojas';

  @override
  String get newStore => 'Nova loja';

  @override
  String get storeNameLabel => 'Nome da loja';

  @override
  String get storeNameRequired => 'O nome da loja é obrigatório';

  @override
  String get renameStoreTitle => 'Renomear loja';

  @override
  String get setAsDefault => 'Definir como padrão';

  @override
  String get defaultStoreLabel => 'Padrão';

  @override
  String get deleteStoreTitle => 'Eliminar loja';

  @override
  String confirmDeleteStoreMessage(String name) {
    return 'Tem a certeza de que deseja eliminar \"$name\"?';
  }

  @override
  String get couldNotDeleteStore => 'Não foi possível eliminar a loja.';

  @override
  String get couldNotCreateStore => 'Não foi possível criar a loja.';

  @override
  String get couldNotRenameStore => 'Não foi possível renomear a loja.';

  @override
  String get currentStoreLabel => 'Loja atual';

  @override
  String get allStoresLabel => 'Todas as lojas';

  @override
  String get perStoreBreakdownTitle => 'Resumo por loja';

  @override
  String get consolidatedStatementLabel =>
      'Extracto consolidado (todas as lojas)';

  @override
  String get consolidatedStatementDescription =>
      'Soma os dados de todas as lojas neste período';

  @override
  String get archiveStoreTitle => 'Arquivar loja';

  @override
  String confirmArchiveStoreMessage(Object name) {
    return 'Tem a certeza que quer arquivar \"$name\"? Os dados desta loja (vendas, clientes, extractos) são preservados, mas deixa de aparecer como loja activa.';
  }

  @override
  String get archiveLabel => 'Arquivar';

  @override
  String get couldNotArchiveStore => 'Não foi possível arquivar a loja.';
}
