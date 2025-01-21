import os
from web3 import Web3
from web3.middleware import geth_poa_middleware
from dotenv import load_dotenv
import json

# Load environment variables
load_dotenv()

# Alchemy Amoy Testnet Configuration
ALCHEMY_API_KEY = os.getenv('ALCHEMY_API_KEY')
PRIVATE_KEY = os.getenv('PRIVATE_KEY')
WALLET_ADDRESS = os.getenv('WALLET_ADDRESS')

# Amoy Testnet RPC URL
AMOY_RPC_URL = f'https://polygon-amoy.g.alchemy.com/v2/{ALCHEMY_API_KEY}'

def deploy_contract():
    # Connect to Amoy Testnet
    w3 = Web3(Web3.HTTPProvider(AMOY_RPC_URL))
    w3.middleware_onion.inject(geth_poa_middleware, layer=0)

    # Check connection
    print(f"Connected to Amoy Testnet: {w3.is_connected()}")

    # Prepare the contract
    with open('LuxuryExperienceNFT.json', 'r') as f:
        contract_data = json.load(f)

    # Get contract ABI and Bytecode
    contract_abi = contract_data['abi']
    contract_bytecode = contract_data['bytecode']

    # Create contract instance
    LuxuryExperienceNFT = w3.eth.contract(abi=contract_abi, bytecode=contract_bytecode)

    # Get the nonce
    nonce = w3.eth.get_transaction_count(WALLET_ADDRESS)

    # Estimate gas
    gas_estimate = LuxuryExperienceNFT.constructor().estimate_gas()

    # Prepare transaction
    transaction = LuxuryExperienceNFT.constructor().build_transaction({
        'chainId': 80002,  # Amoy Testnet Chain ID
        'gas': gas_estimate,
        'gasPrice': w3.eth.gas_price,
        'nonce': nonce,
    })

    # Sign the transaction
    signed_txn = w3.eth.account.sign_transaction(transaction, private_key=PRIVATE_KEY)

    # Send the transaction
    tx_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)

    # Wait for transaction receipt
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

    print(f"Contract deployed at address: {tx_receipt.contractAddress}")
    return tx_receipt.contractAddress

if __name__ == '__main__':
    deploy_contract()
