# Contributing to E-Commerce Provenance System

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported
2. Use the bug report template
3. Provide detailed information including:
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - System information

### Suggesting Features

1. Check if the feature has already been requested
2. Use the feature request template
3. Provide detailed description of the feature
4. Explain the use case and benefits

### Development Setup

1. Fork the repository
2. Clone your fork
3. Install dependencies: `pip install -r requirements.txt`
4. Set up Oracle database using `database/ecommerce_provenance_db.sql`
5. Configure database connection in `app/config.py`

### Making Changes

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make your changes
3. Add tests if applicable
4. Update documentation
5. Commit with descriptive messages
6. Push to your fork
7. Create a Pull Request

### Pull Request Guidelines

- Include a clear description of changes
- Reference related issues
- Ensure tests pass
- Update documentation if needed
- Follow code style guidelines

## Code Style

- Follow PEP 8 for Python code
- Use descriptive variable and function names
- Add docstrings to functions and classes
- Comment complex logic

## Testing

- Write tests for new features
- Ensure existing tests pass
- Test on multiple environments if possible

## Documentation

- Update README.md for new features
- Add docstrings to new functions
- Update API documentation if applicable
