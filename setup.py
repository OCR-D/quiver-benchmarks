# -*- coding: utf-8 -*-
from setuptools import setup, find_packages

install_requires = open('requirements.txt').read().split('\n')

setup(
    name='quiver_benchmarks',
    version='0.1.0',
    description='Benchmarks for the OCR-D QuiVer web app',
    long_description=open('README.md').read(),
    long_description_content_type='text/markdown',
    author='Michelle Weidling',
    author_email='weidling@sub.uni-goettingen.de',
    url='https://github.com/OCR-D/quiver-benchmarks',
    license='MIT',
    packages=find_packages(exclude=('tests', 'docs')),
    include_package_data=True,
    install_requires=install_requires,
    package_data={
        '': ['*.json', '*.yml', '*.yaml', '*.list', '*.xml'],
    },
    entry_points={
        'console_scripts': [
            'quiver=src.cli:cli',
        ]
    },
)
