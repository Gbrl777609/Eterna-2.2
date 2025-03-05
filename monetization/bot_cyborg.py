import os
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import ApplicationBuilder, CommandHandler, CallbackQueryHandler

TOKEN = "TU_TOKEN_AQUÍ"  # Reemplazar por token real
ADMIN_ID = TU_ID_TELEGRAM  # Reemplazar por tu ID
BTC_ADDR = "bc1qyd5sp44uk37x3hnyzaa6nkcsrka0rqte9kd3y3"
ETH_ADDR = "0x292E82Ca2713797561184e12b862B57787ae4b7c"

async def start(update: Update, _):
    if update.effective_user.id != ADMIN_ID:
        return
    keyboard = [
        [InlineKeyboardButton("💰 BTC", callback_data='btc'),
         InlineKeyboardButton("💎 ETH", callback_data='eth')],
        [InlineKeyboardButton("📜 Estrategias", url='https://github.com/Gbrl777609/Eterna-2.1/blob/main/monetization/estrategias.md')]
    ]
    await update.message.reply_text(
        "⚡ *Fondo Cuántico Eterna-Ψ*\n"
        "▸ Objetivo: 0.5 BTC / 5 ETH\n"
        "▸ Progreso: https://github.com/Gbrl777609/Eterna-2.1",
        reply_markup=InlineKeyboardMarkup(keyboard),
        parse_mode="Markdown"
    )

async def button(update: Update, _):
    query = update.callback_query
    await query.answer()
    if query.data == 'btc':
        await query.edit_message_text(f"`{BTC_ADDR}`\n🔗 *Explorador:* https://blockchain.info/tx/", parse_mode="Markdown")
    elif query.data == 'eth':
        await query.edit_message_text(f"`{ETH_ADDR}`\n🔗 *Explorador:* https://etherscan.io/tx/", parse_mode="Markdown")

if __name__ == "__main__":
    app = ApplicationBuilder().token(TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CallbackQueryHandler(button))
    app.run_polling()
