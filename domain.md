# 📱 App Financeiro Pessoal (Android) — Documento Completo

---

# 🎯 Objetivo

Aplicativo Android para controle financeiro pessoal com:

* Entrada rápida de gastos (voz + manual)
* Controle de saldo real
* Cartões de crédito com faturas
* Parcelamentos
* Ajustes manuais de fatura
* Backup manual em JSON por ano
* 100% offline-first

---

# 🏗️ Stack Tecnológica

* Kotlin
* Jetpack Compose
* Room (SQLite)
* MVVM
* Gson ou Kotlinx Serialization
* Storage Access Framework (backup/restore)

---

# 💰 Estratégia de Dinheiro (CRÍTICO)

## Regra principal

Todos os valores monetários devem ser armazenados como:

👉 **Long representando centavos**

---

## ❌ Nunca usar

* Double
* Float

---

## 💡 Classe Money (OBRIGATÓRIA)

```kotlin
@JvmInline
value class Money(val cents: Long) {

    operator fun plus(other: Money) = Money(this.cents + other.cents)

    operator fun minus(other: Money) = Money(this.cents - other.cents)

    operator fun unaryMinus() = Money(-cents)

    fun isNegative() = cents < 0

    fun isPositive() = cents > 0

    fun format(): String {
        val value = cents / 100.0
        return "R$ %.2f".format(value)
    }

    companion object {
        fun fromReais(value: String): Money {
            val normalized = value.replace(",", ".")
            val cents = (normalized.toBigDecimal() * java.math.BigDecimal(100)).toLong()
            return Money(cents)
        }
    }
}
```

---

# 🧠 Entidades (Room)

## Account

```kotlin
@Entity
data class Account(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val name: String,
    val type: String,
    val balanceInCents: Long
)
```

---

## CreditCard

```kotlin
@Entity
data class CreditCard(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val name: String,
    val limitInCents: Long,
    val closingDay: Int,
    val dueDay: Int
)
```

---

## Transaction

```kotlin
@Entity
data class Transaction(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,

    val amountInCents: Long,
    val type: String, // EXPENSE, INCOME

    val category: String,
    val description: String,

    val date: Long,

    val paymentMethod: String, // PIX, DEBIT, CREDIT, BOLETO

    val accountId: Int?,
    val cardId: Int?,

    val installmentId: Int?
)
```

---

## Installment

```kotlin
@Entity
data class Installment(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val totalAmountInCents: Long,
    val totalMonths: Int
)
```

---

## Invoice

```kotlin
@Entity
data class Invoice(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,

    val cardId: Int,
    val month: Int,
    val year: Int,

    val totalInCents: Long,
    val adjustedTotalInCents: Long?,

    val isClosed: Boolean,
    val isPaid: Boolean
)
```

---

## IncomeRule

```kotlin
@Entity
data class IncomeRule(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val amountInCents: Long,
    val dayOfMonth: Int
)
```

---

# 🧾 ENUMS

```kotlin
enum class TransactionType {
    EXPENSE,
    INCOME
}

enum class PaymentMethod {
    PIX,
    DEBIT,
    CREDIT,
    BOLETO
}
```

---

# 💳 Regras de Negócio

## Cartão de crédito

* NÃO altera saldo imediato
* Vai para fatura

---

## Regra de fatura

Se:

* dia da compra <= closingDay → fatura atual
* dia da compra > closingDay → próxima fatura

---

## Cálculo da fatura

```kotlin
val total = transactions.sumOf { it.amountInCents }
```

Se existir:

```kotlin
adjustedTotalInCents != null
```

👉 usar valor ajustado

---

## Parcelamento

* Criar N transações futuras
* Cada parcela = total / meses
* Datas incrementadas mensalmente

---

## Saldo total

```text
Saldo = contas (dinheiro real)
       - faturas abertas
```

---

# 🎤 Entrada por voz

Fluxo:

1. Speech-to-text (Android nativo)
2. Parser (regex/local)
3. Extrair:

   * valor
   * categoria
4. Converter para centavos
5. Criar Transaction

---

# 💾 Backup

## Estratégia

* Manual via botão
* JSON
* Separado por ano

---

## Arquivos

```text
gastos_2024.json
gastos_2025.json
gastos_2026.json
```

---

## Exportação

* Filtrar por ano
* Serializar JSON
* Salvar via seletor de arquivos

---

## Restauração

* Ler JSON
* Converter para lista
* Deletar dados do ano
* Inserir novos

---

# 🧠 DAO (exemplo)

```kotlin
@Dao
interface TransactionDao {

    @Insert
    suspend fun insert(transaction: Transaction)

    @Insert
    suspend fun insertAll(transactions: List<Transaction>)

    @Query("SELECT * FROM Transaction")
    suspend fun getAll(): List<Transaction>

    @Query("""
        DELETE FROM Transaction 
        WHERE strftime('%Y', date / 1000, 'unixepoch') = :year
    """)
    suspend fun deleteByYear(year: String)
}
```

---

# ⚠️ Regras obrigatórias

* Nunca usar Double
* Sempre usar centavos
* Nunca alterar transações originais
* Ajustes via `adjustedTotalInCents`
* Sistema deve funcionar offline
* Backup manual obrigatório

---

# 🚀 Roadmap

## Fase 1

* Transaction + Account + saldo

## Fase 2

* Cartão + Invoice

## Fase 3

* Parcelamento

## Fase 4

* Backup/Restore

## Fase 5

* Entrada por voz

---

# 💡 Objetivo final

Sistema financeiro pessoal robusto, confiável e previsível,
com precisão total nos cálculos e controle completo do usuário.
