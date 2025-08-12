use aes_gcm::{
    aead::{Aead, KeyInit, OsRng},
    Aes256Gcm, Key, Nonce,
};
use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use argon2::password_hash::{rand_core::RngCore, SaltString};
use anyhow::{Result, anyhow};

pub struct Encryptor {
    cipher: Aes256Gcm,
}

impl Encryptor {
    pub fn new(password: &str) -> Result<Self> {
        let salt = SaltString::generate(&mut OsRng);
        let argon2 = Argon2::default();
        let password_hash = argon2
            .hash_password(password.as_bytes(), &salt)
            .map_err(|e| anyhow!("Failed to hash password: {}", e))?;
        
        let hash_output = password_hash.hash.unwrap();
        let key_bytes = hash_output.as_bytes();
        let mut key = [0u8; 32];
        key.copy_from_slice(&key_bytes[..32]);
        
        let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(&key));
        
        Ok(Self { cipher })
    }
    
    pub fn encrypt(&self, plaintext: &[u8]) -> Result<Vec<u8>> {
        let mut nonce_bytes = [0u8; 12];
        OsRng.fill_bytes(&mut nonce_bytes);
        let nonce = Nonce::from_slice(&nonce_bytes);
        
        let ciphertext = self.cipher
            .encrypt(nonce, plaintext)
            .map_err(|e| anyhow!("Encryption failed: {}", e))?;
        
        let mut result = nonce_bytes.to_vec();
        result.extend_from_slice(&ciphertext);
        
        Ok(result)
    }
    
    pub fn decrypt(&self, ciphertext: &[u8]) -> Result<Vec<u8>> {
        if ciphertext.len() < 12 {
            return Err(anyhow!("Invalid ciphertext"));
        }
        
        let (nonce_bytes, encrypted) = ciphertext.split_at(12);
        let nonce = Nonce::from_slice(nonce_bytes);
        
        let plaintext = self.cipher
            .decrypt(nonce, encrypted)
            .map_err(|e| anyhow!("Decryption failed: {}", e))?;
        
        Ok(plaintext)
    }
}